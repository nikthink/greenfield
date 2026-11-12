# cat_name.s — read a filename from stdin, echo it, then print the file.
# GNU as, AT&T syntax, x86-64 Linux, raw syscalls (no libc).
#
# Build:  as cat_name.s -o cat_name.o && ld cat_name.o -o cat_name
# Run:    echo /etc/hostname | ./cat_name
#
# AT&T syntax cheat sheet:
#   mnemonic  src, dst        -> operands are source first, destination last
#   %reg                      -> register      e.g. %rax
#   $imm                      -> immediate     e.g. $60
#   sym(%rip)                 -> RIP-relative memory reference (position-independent)
#   disp(base,index,scale)    -> memory: base + index*scale + disp
#   suffix b/w/l/q            -> 8/16/32/64-bit operand size (movb, movq ...),
#                                optional when a register already implies the size
#
# Linux x86-64 syscall ABI:
#   %rax = syscall number, args in %rdi, %rsi, %rdx, %r10, %r8, %r9
#   return value in %rax (negative = -errno); syscall clobbers %rcx and %r11

    .set SYS_read,   0          # .set NAME, value -> assemble-time constant
    .set SYS_write,  1
    .set SYS_close,  3
    .set SYS_exit,   60
    .set SYS_openat, 257
    .set AT_FDCWD,   -100       # openat: path relative to current directory
    .set O_RDONLY,   0
    .set STDIN,      0
    .set STDOUT,     1
    .set BUFSZ,      4096

    .section .bss               # zero-initialised, takes no space in the file
    .balign 16                  # align next symbol to 16 bytes
name:   .zero 4096              # reserve 4096 bytes for the filename
buf:    .zero BUFSZ             # file copy buffer

    .section .rodata            # read-only data
nl:     .byte '\n'              # a single newline character

    .text                       # code section
    .globl _start               # export entry point so ld can find it
    .type  _start, @function    # symbol type metadata (for debuggers/tools)
_start:
    # ---- read(STDIN, name, 4095) : get the filename ----
    mov     $SYS_read, %eax     # writing %eax zero-extends into %rax
    mov     $STDIN, %edi
    lea     name(%rip), %rsi    # lea = load effective address (pointer, not value)
    mov     $4095, %edx         # leave room for a terminating NUL
    syscall
    test    %rax, %rax          # sets flags from rax & rax
    jle     fail                # <= 0 bytes read -> error / EOF

    # ---- strip a trailing '\n' if present ----
    mov     %rax, %rbx          # rbx = length (callee-saved, survives syscalls)
    lea     name(%rip), %rsi
    cmpb    $'\n', -1(%rsi,%rbx)    # compare byte at name[len-1]; 'b' = byte size
    jne     1f                  # 1f = jump forward to the next local label "1:"
    dec     %rbx
1:  movb    $0, (%rsi,%rbx)     # NUL-terminate: open() needs a C string

    # ---- write(STDOUT, name, len) then a newline ----
    mov     $SYS_write, %eax
    mov     $STDOUT, %edi
    mov     %rbx, %rdx          # rsi still points at name
    syscall

    mov     $SYS_write, %eax
    mov     $STDOUT, %edi
    lea     nl(%rip), %rsi
    mov     $1, %edx
    syscall

    # ---- openat(AT_FDCWD, name, O_RDONLY) ----
    mov     $SYS_openat, %eax
    mov     $AT_FDCWD, %rdi     # 64-bit mov: sign matters, -100 must be full width
    lea     name(%rip), %rsi
    mov     $O_RDONLY, %edx
    syscall
    test    %rax, %rax
    js      fail                # sign flag set -> negative -> -errno
    mov     %rax, %r12          # r12 = fd (callee-saved)

    # ---- loop: n = read(fd, buf, BUFSZ); write(STDOUT, buf, n) ----
copy:
    mov     $SYS_read, %eax
    mov     %r12, %rdi
    lea     buf(%rip), %rsi
    mov     $BUFSZ, %edx
    syscall
    test    %rax, %rax
    js      fail                # read error
    jz      done                # 0 = end of file

    mov     %rax, %rdx          # byte count to write
    mov     $SYS_write, %eax
    mov     $STDOUT, %edi
    lea     buf(%rip), %rsi     # rsi survives syscall; reloaded only for clarity
    syscall
    test    %rax, %rax
    js      fail                # (short writes ignored to keep it simple)
    jmp     copy

done:
    mov     $SYS_close, %eax
    mov     %r12, %rdi
    syscall
    xor     %edi, %edi          # exit code 0 (xor reg,reg = idiomatic zero)
    jmp     exit

fail:
    mov     $1, %edi            # exit code 1
exit:
    mov     $SYS_exit, %eax
    syscall
    .size _start, . - _start    # '.' = current address -> symbol size

    # Mark the stack non-executable; modern ld warns without this.
    .section .note.GNU-stack, "", @progbits
