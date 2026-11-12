    .set EOF, -1

    .section .rodata
msg: .asciz "hello %d\n"


    .text
    .globl main
main:
    push %rbp                # align stack to 16 bytes
ls: call getchar@PLT
    cmp $EOF, %eax
    je done
    mov %eax, %edi
    call putchar@PLT
    mov $'\n', %edi
    call putchar@PLT
    jmp ls
done:
    mov  $0, %eax            # return 0
    pop  %rbp                # undo the push so ret finds the return address
    ret


    .section .note.GNU-stack,"",@progbits
