# "Every C function uses the same rule, the System V x86-64 calling convention" :
# for integer or pointer arguments: 1st: %rdi, 2nd: %rsi, 3rd: %rdx, 4th: %rcx
# and return value in %rax for integer/pointers
# look at man to see c func signature, ex `man puts.3`
# some registers that are not touched by c lib func: %rbx, %r12, %r13, %r14, %r15

    .set EOF, -1

    .section .rodata
cerr_str: .asciz "error: COMPILATION ERROR"
genp_start_str: .asciz "    .text\n    .globl main\nmain:\n    push %rbp"
genp_end_str: .asciz "    mov $0, %eax\n    pop %rbp\n    ret"
cmd_z_str: .asciz "    push $0\n    push $0"
cmd_d_str: .asciz "    push $0\n    push 8(%rsp)"
cmd_i_str: .asciz "    pop %rax\n   pop %rbx\n    add $1, %rax\n    push $0\n    push %rax"
cmd_r_str: .asciz "    call getchar@PLT\n    push $0\n    push %rax"
cmd_w_str: .asciz "    pop %rdi\n    pop %rbx\n    call putchar@PLT"
cmd_c_str: .asciz "    pop %rax\n    pop %r12\n    pop %rbx\n    pop %r12\n    sub %rax, %rbx\n    push $0\n    push %rbx"
cmd_j_str: .asciz "j:"
cmd_k_str: .asciz "    pop %rax\n    pop %r12\ncmp $0, %rax\n    je j"
push_lit_start_str: .asciz "    push $0\n    push $'"
push_lit_end_str: .asciz "'\n"
print_lit_start_str: .asciz "    mov $'"
print_lit_end_str: .asciz "', %rdi\n    call putchar@PLT\n"


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
    cmp $'Z', %rdi
    je cmd_z
    cmp $'D', %rdi
    je cmd_d
    cmp $'R', %rdi
    je cmd_r
    cmp $'W', %rdi
    je cmd_w
    cmp $'I', %rdi
    je cmd_i
    cmp $'S', %rdi
    je cmd_s
    cmp $'P', %rdi
    je cmd_p
    cmp $'C', %rdi
    je cmd_c
    cmp $'J', %rdi
    je cmd_j
    cmp $'K', %rdi
    je cmd_k
    cmp $'\n', %rdi
    je pcmd_ret
    cmp $' ', %rdi
    je pcmd_ret
    cmp $'\t', %rdi
    je pcmd_ret
    lea cerr_str(%rip), %rdi
    call puts@PLT
pcmd_ret:
    ret
cmd_z:
    lea cmd_z_str(%rip), %rdi
    call puts@PLT
    ret
cmd_d:
    lea cmd_d_str(%rip), %rdi
    call puts@PLT
    ret
cmd_w:
    lea cmd_w_str(%rip), %rdi
    call puts@PLT
    ret
cmd_r:
    lea cmd_r_str(%rip), %rdi
    call puts@PLT
    ret
cmd_i:
    lea cmd_i_str(%rip), %rdi
    call puts@PLT
    ret
cmd_c:
    lea cmd_c_str(%rip), %rdi
    call puts@PLT
    ret
cmd_j:
    lea cmd_j_str(%rip), %rdi
    call puts@PLT
    ret
cmd_k:
    lea cmd_k_str(%rip), %rdi
    call puts@PLT
    ret
cmd_s:
    call getchar@PLT
    cmp $'Q', %eax
    je pcmd_ret
    mov %rax, %rbx
    lea print_lit_start_str(%rip), %rdi
    call print_no_nl
    mov %rbx, %rdi
    call putchar@PLT
    lea print_lit_end_str(%rip), %rdi
    call print_no_nl
    jmp cmd_s
cmd_p:
    call getchar@PLT
    mov %rax, %rbx
    lea push_lit_start_str(%rip), %rdi
    call print_no_nl
    mov %rbx, %rdi
    call putchar@PLT
    lea push_lit_end_str(%rip), %rdi
    call print_no_nl
    ret

print_no_nl: # lea   name(%rip), %rdi
    mov   stdout@GOTPCREL(%rip), %rsi   # address of the stdout variable
    mov   (%rsi), %rsi                  # 2nd arg: its value, the FILE*
    call  fputs@PLT
    ret

    .section .note.GNU-stack,"",@progbits #instruct linker to mark stack as non-executable
