    .section .rodata
msg: .asciz "hello %d\n"
    .text
    .globl main
main:
    sub  $8, %rsp            # %rsp is 16-byte aligned again before the call
    lea  msg(%rip), %rdi     # 1st argument: the format string
    mov  $42, %esi           # 2nd argument
    xor  %eax, %eax          # %al = number of vector registers used (0)
    call printf@PLT          # @PLT goes through the procedure linkage table
    xor  %eax, %eax          # return 0
    add  $8, %rsp
    ret
    .section .note.GNU-stack,"",@progbits
