# Peca 4 - tabela unica de instrucoes
# Copiado do main.asm: instnames, fmttab, optab, f3tab, f7tab e a rotina lookup.
# Cada instrucao ocupa a mesma posicao em todas as tabelas. lookup acha o indice pelo nome e as outras
# tabelas dizem o formato dos operandos, o opcode, o funct3 e o funct7 (bits 6:0, 14:12 e 31:25 da palavra).
# Parte 1: indice de cada nome (-1 = instrucao inexistente).
# Parte 2: campos de algumas instrucoes (valores da especificacao RISC-V).

.data
.eqv N_INST, 37
.align 3
instnames:
    .asciz "add"
    .align 3
    .asciz "sub"
    .align 3
    .asciz "sll"
    .align 3
    .asciz "slt"
    .align 3
    .asciz "sltu"
    .align 3
    .asciz "xor"
    .align 3
    .asciz "srl"
    .align 3
    .asciz "sra"
    .align 3
    .asciz "or"
    .align 3
    .asciz "and"
    .align 3
    .asciz "addi"
    .align 3
    .asciz "slti"
    .align 3
    .asciz "sltiu"
    .align 3
    .asciz "xori"
    .align 3
    .asciz "ori"
    .align 3
    .asciz "andi"
    .align 3
    .asciz "slli"
    .align 3
    .asciz "srli"
    .align 3
    .asciz "srai"
    .align 3
    .asciz "lb"
    .align 3
    .asciz "lh"
    .align 3
    .asciz "lw"
    .align 3
    .asciz "lbu"
    .align 3
    .asciz "lhu"
    .align 3
    .asciz "jalr"
    .align 3
    .asciz "sb"
    .align 3
    .asciz "sh"
    .align 3
    .asciz "sw"
    .align 3
    .asciz "lui"
    .align 3
    .asciz "auipc"
    .align 3
    .asciz "beq"
    .align 3
    .asciz "bne"
    .align 3
    .asciz "blt"
    .align 3
    .asciz "bge"
    .align 3
    .asciz "bltu"
    .align 3
    .asciz "bgeu"
    .align 3
    .asciz "jal"
    .align 3
fmttab:  .byte 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 3, 5, 5, 5, 6, 6, 7, 7, 7, 7, 7, 7, 8
optab:   .byte 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x03, 0x03, 0x03, 0x03, 0x03, 0x67, 0x23, 0x23, 0x23, 0x37, 0x17, 0x63, 0x63, 0x63, 0x63, 0x63, 0x63, 0x6F
f3tab:   .byte 0, 0, 1, 2, 3, 4, 5, 5, 6, 7, 0, 2, 3, 4, 6, 7, 1, 5, 5, 0, 1, 2, 4, 5, 0, 0, 1, 2, 0, 0, 0, 1, 4, 5, 6, 7, 0
f7tab:   .byte 0, 32, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
.align 2
casos:
    .word c0
    .word 0
    .word c1
    .word 1
    .word c2
    .word 9
    .word c3
    .word 10
    .word c4
    .word 21
    .word c5
    .word 23
    .word c6
    .word 24
    .word c7
    .word 27
    .word c8
    .word 28
    .word c9
    .word 30
    .word c10
    .word 36
    .word c11
    .word -1
    .word c12
    .word -1
    .word c13
    .word -1
    .word 0
c0: .asciz "add"
c1: .asciz "sub"
c2: .asciz "and"
c3: .asciz "addi"
c4: .asciz "lw"
c5: .asciz "lhu"
c6: .asciz "jalr"
c7: .asciz "sw"
c8: .asciz "lui"
c9: .asciz "beq"
c10: .asciz "jal"
c11: .asciz "mul"
c12: .asciz "ad"
c13: .asciz "addii"
t_obtido:   .asciz "  obtido="
t_esperado: .asciz "  esperado="
t_seta:     .asciz "  -> "
t_ok:       .asciz "OK"
t_erro:     .asciz "ERRO"
t_nl:       .asciz "\n"
d_nome: .asciz "nome -> indice"
d_op: .asciz "opcode"
d_f3: .asciz "funct3"
d_f7: .asciz "funct7"
q_add:  .asciz "sub"
q_lhu:  .asciz "lhu"
q_beq:  .asciz "bne"

.text
main:
    la   s0, casos
caso:
    lw   s1, 0(s0)
    beqz s1, campos
    lw   s2, 4(s0)
    mv   a0, s1
    call tam_str
    mv   a1, a0
    mv   a0, s1
    la   a2, instnames
    li   a3, N_INST
    call lookup
    mv   a1, s2
    mv   a2, s1
    call confere
    addi s0, s0, 8
    j    caso
campos:
    la   a0, q_add
    li   a1, 3
    li   a2, 0x33
    li   a3, 32
    call mostra
    la   a0, q_lhu
    li   a1, 3
    li   a2, 0x03
    li   a3, 0
    call mostra
    la   a0, q_beq
    li   a1, 3
    li   a2, 0x63
    li   a3, 0
    call mostra
    li   a7, 10
    ecall

mostra:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   a2, 8(sp)
    sw   a3, 4(sp)
    sw   a0, 0(sp)
    call tam_str
    mv   a1, a0
    lw   a0, 0(sp)
    la   a2, instnames
    li   a3, N_INST
    call lookup
    mv   s3, a0
    lw   a0, 0(sp)
    li   a7, 4
    ecall
    la   a0, t_nl
    ecall
    la   t0, optab
    add  t0, t0, s3
    lbu  a0, 0(t0)
    lw   a1, 8(sp)
    la   a2, d_op
    call confere_hex
    la   t0, f7tab
    add  t0, t0, s3
    lbu  a0, 0(t0)
    lw   a1, 4(sp)
    la   a2, d_f7
    call confere
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret
lookup:
    li   t0, 0
lookup_entry:
    bgeu t0, a3, lookup_none
    slli t1, t0, 3
    add  t1, t1, a2
    li   t2, 0
lookup_char:
    bgeu t2, a1, lookup_tail
    add  t3, a0, t2
    lbu  t3, 0(t3)
    add  t4, t1, t2
    lbu  t4, 0(t4)
    bne  t3, t4, lookup_next
    addi t2, t2, 1
    j    lookup_char
lookup_tail:
    add  t4, t1, a1
    lbu  t4, 0(t4)
    beqz t4, lookup_found
lookup_next:
    addi t0, t0, 1
    j    lookup_entry
lookup_found:
    mv   a0, t0
    ret
lookup_none:
    li   a0, -1
    ret

tam_str:
    li   t0, 0
tam_str_loop:
    add  t1, a0, t0
    lbu  t1, 0(t1)
    beqz t1, tam_str_fim
    addi t0, t0, 1
    j    tam_str_loop
tam_str_fim:
    mv   a0, t0
    ret

confere:
    mv   t0, a0
    mv   t1, a1
    mv   a0, a2
    li   a7, 4
    ecall
    la   a0, t_obtido
    ecall
    mv   a0, t0
    li   a7, 1
    ecall
    la   a0, t_esperado
    li   a7, 4
    ecall
    mv   a0, t1
    li   a7, 1
    ecall
    la   a0, t_seta
    li   a7, 4
    ecall
    la   a0, t_ok
    beq  t0, t1, confere_fim
    la   a0, t_erro
confere_fim:
    li   a7, 4
    ecall
    la   a0, t_nl
    ecall
    ret

confere_hex:
    mv   t0, a0
    mv   t1, a1
    mv   a0, a2
    li   a7, 4
    ecall
    la   a0, t_obtido
    ecall
    mv   a0, t0
    li   a7, 34
    ecall
    la   a0, t_esperado
    li   a7, 4
    ecall
    mv   a0, t1
    li   a7, 34
    ecall
    la   a0, t_seta
    li   a7, 4
    ecall
    la   a0, t_ok
    beq  t0, t1, confere_hex_fim
    la   a0, t_erro
confere_hex_fim:
    li   a7, 4
    ecall
    la   a0, t_nl
    ecall
    ret
