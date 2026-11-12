# "Every C function uses the same rule, the System V x86-64 calling convention" :
# for integer or pointer arguments: 1st: %rdi, 2nd: %rsi, 3rd: %rdx, 4th: %rcx
# and return value in %rax for integer/pointers
# look at man to see c func signature, ex `man puts.3`

    .set EOF, -1

    .section .rodata
cmd_h_str: .asciz "    mov $'H', %rdi\n    call putchar@PLT"
cerr_str: .asciz "error: COMPILATION ERROR"
genp_start_str: .asciz "    .text\n    .globl main\nmain:\n    push %rbp"
genp_end_str: .asciz "    mov $0, %eax\n    pop %rbp\n    ret"


    .text
    .globl main
main:
    push %rbp                # align stack to 16 bytes

    lea genp_start_str(%rip), %rdi
    call puts@PLT
ls: call getchar@PLT
    cmp $EOF, %eax
    je done
    mov %rax, %rdi
    call pcmd
    jmp ls
done:
    lea genp_end_str(%rip), %rdi
    call puts@PLT
    mov  $0, %eax            # return 0
    pop  %rbp                # undo the push so ret finds the return address
    ret

pcmd:
    cmp $'h', %rdi
    je cmd_h
    cmp $'\n', %rdi
    je pcmd_ret
    lea cerr_str(%rip), %rdi
    call puts@PLT
pcmd_ret:
    ret
cmd_h:
    lea cmd_h_str(%rip), %rdi
    call puts@PLT
    ret


    .section .note.GNU-stack,"",@progbits #instruct linker to mark stack as non-executable
