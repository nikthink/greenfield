# cat_name.s — read a filename from stdin, echo it, then print the file.
# GNU as, AT&T syntax, x86-64 ELF, portable: calls only ISO C stdio (no raw
# syscalls), so it runs on any ELF system with a C library (Linux, BSDs, ...).
#
# Build:  cc cat_name.s -o cat_name      (cc links libc and the C runtime)
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
# System V x86-64 C calling convention:
#   int/pointer args in %rdi, %rsi, %rdx, %rcx, %r8, %r9; return value in %rax
#   %rbx, %rbp, %r12-%r15 are callee-saved (survive calls); everything else
#   may be clobbered. %rsp must be 16-byte aligned at every call instruction.

    .set NAMESZ, 4096           # .set NAME, value -> assemble-time constant
    .set EOF,    -1

    .section .bss               # zero-initialised, takes no space in the file
    .balign 16                  # align next symbol to 16 bytes
name:   .zero NAMESZ            # reserve space for the filename

    .section .rodata            # read-only data
mode:   .asciz "rb"             # fopen mode string (NUL-terminated)

    .text                       # code section
    .globl main                 # export main; the C runtime calls it
    .type  main, @function      # symbol type metadata (for debuggers/tools)
main:
    # On entry %rsp is 8 mod 16 (call pushed the return address).
    # Two pushes (16 bytes) + 8 more -> 16-byte aligned for our calls.
    push    %rbx
    push    %r12
    sub     $8, %rsp

    # ---- read the filename one char at a time with getchar() ----
    xor     %ebx, %ebx          # rbx = length (callee-saved, survives calls)
1:  cmp     $NAMESZ-1, %ebx     # leave room for a terminating NUL
    jae     2f                  # 2f = jump forward to the next local label "2:"
    call    getchar@PLT         # returns int: a char, or EOF (-1)
    cmp     $EOF, %eax
    je      2f
    cmp     $'\n', %eax         # stop at newline (not stored)
    je      2f
    lea     name(%rip), %rdx    # lea = load effective address (pointer, not value)
    movb    %al, (%rdx,%rbx)    # name[len] = c; 'b' = byte size
    inc     %ebx
    jmp     1b                  # 1b = jump backward to the previous "1:"
2:  test    %ebx, %ebx
    jz      fail                # empty name -> error
    lea     name(%rip), %rdx
    movb    $0, (%rdx,%rbx)     # NUL-terminate: C functions need a C string

    # ---- puts(name) : prints the name plus a newline ----
    lea     name(%rip), %rdi
    call    puts@PLT

    # ---- fp = fopen(name, "rb") ----
    lea     name(%rip), %rdi
    lea     mode(%rip), %rsi
    call    fopen@PLT
    test    %rax, %rax
    jz      fail                # NULL -> could not open
    mov     %rax, %r12          # r12 = FILE* (callee-saved)

    # ---- loop: while ((c = fgetc(fp)) != EOF) putchar(c); ----
copy:
    mov     %r12, %rdi
    call    fgetc@PLT
    cmp     $EOF, %eax
    je      done
    mov     %eax, %edi
    call    putchar@PLT
    jmp     copy

done:
    # EOF means end-of-file *or* error; ferror() tells them apart.
    mov     %r12, %rdi
    call    ferror@PLT
    mov     %eax, %ebx          # remember error flag across fclose
    mov     %r12, %rdi
    call    fclose@PLT
    xor     %eax, %eax          # exit code 0 (xor reg,reg = idiomatic zero)
    test    %ebx, %ebx
    jz      out

fail:
    mov     $1, %eax            # exit code 1
out:
    # Returning from main (instead of a raw exit syscall) lets the C runtime
    # run exit(), which flushes stdout's buffer.
    add     $8, %rsp
    pop     %r12
    pop     %rbx
    ret
    .size main, . - main        # '.' = current address -> symbol size

    # Mark the stack non-executable; modern ld warns without this.
    .section .note.GNU-stack, "", @progbits
