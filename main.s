    .section .rodata
msg: .asciz "hello %d\n"


    .text
    .globl main
main:
    push %rbp                # 8 bytes: %rsp is 16-byte aligned again before the call
    lea  msg(%rip), %rdi     # 1st argument: the format string
    mov  $42, %esi           # 2nd argument
    mov  $0, %eax            # %al = number of vector registers used (0)
    call printf@PLT          # @PLT goes through the procedure linkage table
    mov  $0, %eax            # return 0
    pop  %rbp                # undo the push so ret finds the return address
    ret


    .section .note.GNU-stack,"",@progbits
