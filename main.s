# "Every C function uses the same rule, the System V x86-64 calling convention" :
# for integer or pointer arguments: 1st: %rdi, 2nd: %rsi, 3rd: %rdx, 4th: %rcx
# and return value in %rax for integer/pointers
# look at man to see c func signature, ex `man puts.3`

    .set EOF, -1

    .section .rodata
cmd_g_str: .asciz "    call getchar@PLT\n    push %eax"
cerr_str: .asciz "error: COMPILATION ERROR"


    .text
    .globl main
main:
    push %rbp                # align stack to 16 bytes

ls: call getchar@PLT
    cmp $EOF, %eax
    je done
    mov %rax, %rdi
    call pcmd
    jmp ls
done:
    mov  $0, %eax            # return 0
    pop  %rbp                # undo the push so ret finds the return address
    ret

pcmd:
    cmp $'g', %rdi
    je cmd_g
    cmp $'\n', %rdi
    je pcmd_ret
    lea cerr_str(%rip), %rdi
    call puts@PLT
pcmd_ret:
    ret
cmd_g:
    lea cmd_g_str(%rip), %rdi
    call puts@PLT
    ret

    .section .note.GNU-stack,"",@progbits #instruct linker to mark stack as non-executable
