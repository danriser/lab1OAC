# Peca 2 - ler um imediato
# Rotinas copiadas do main.asm: skip_ws, parse_imm.
# Converte o texto em um numero de 32 bits: decimal, negativo, com + e hexa 0x.
# Devolve valor (a1) e status (a2): 0 ok, 1 invalido/ausente, 2 nao cabe em 32 bits.
# Cada caso: texto, valor esperado, status esperado.

.data
casos:
    .word c0
    .word 10
    .word 0
    .word c1
    .word -42
    .word 0
    .word c2
    .word 7
    .word 0
    .word c3
    .word 255
    .word 0
    .word c4
    .word 2047
    .word 0
    .word c5
    .word -2048
    .word 0
    .word c6
    .word -1
    .word 0
    .word c7
    .word 5
    .word 0
    .word c8
    .word 2147483647
    .word 0
    .word c9
    .word -2147483648
    .word 0
    .word c10
    .word 0
    .word 1
    .word c11
    .word 0
    .word 1
    .word c12
    .word 0
    .word 1
    .word c13
    .word 0
    .word 2
    .word c14
    .word 0
    .word 2
    .word c15
    .word 0
    .word 2
    .word 0
c0: .asciz "10"
c1: .asciz "-42"
c2: .asciz "+7"
c3: .asciz "0xFF"
c4: .asciz "0x7FF"
c5: .asciz "-2048"
c6: .asciz "0xFFFFFFFF"
c7: .asciz "  5"
c8: .asciz "2147483647"
c9: .asciz "-2147483648"
c10: .asciz "abc"
c11: .asciz "0x"
c12: .asciz ""
c13: .asciz "4294967296"
c14: .asciz "0x100000000"
c15: .asciz "2147483648"
t_obtido:   .asciz "  obtido="
t_esperado: .asciz "  esperado="
t_seta:     .asciz "  -> "
t_ok:       .asciz "OK"
t_erro:     .asciz "ERRO"
t_nl:       .asciz "\n"
d_valor: .asciz "  valor"
d_status: .asciz "  status"

.text
main:
    la   s0, casos
caso:
    lw   s1, 0(s0)
    beqz s1, fim
    mv   a0, s1
    call tam_str
    add  a1, s1, a0
    mv   a0, s1
    call parse_imm
    mv   s3, a1
    mv   s4, a2
    mv   a0, s1
    li   a7, 4
    ecall
    la   a0, t_nl
    ecall
    mv   a0, s3
    lw   a1, 4(s0)
    la   a2, d_valor
    call confere
    mv   a0, s4
    lw   a1, 8(s0)
    la   a2, d_status
    call confere
    addi s0, s0, 12
    j    caso
fim:
    li   a7, 10
    ecall
skip_ws:
    bgeu a0, a1, skip_ws_ret
    lbu  t0, 0(a0)
    li   t1, 32
    beq  t0, t1, skip_ws_next
    li   t1, 9
    beq  t0, t1, skip_ws_next
    li   t1, 13
    bne  t0, t1, skip_ws_ret
skip_ws_next:
    addi a0, a0, 1
    j    skip_ws
skip_ws_ret:
    ret

parse_imm:
    addi sp, sp, -16
    sw   ra, 12(sp)
    call skip_ws
    li   t6, 0
    bgeu a0, a1, imm_erro
    lbu  t0, 0(a0)
    li   t1, 45
    bne  t0, t1, imm_mais
    li   t6, 1
    addi a0, a0, 1
    j    imm_inicio
imm_mais:
    li   t1, 43
    bne  t0, t1, imm_inicio
    addi a0, a0, 1
imm_inicio:
    li   t2, 0
    li   t5, 0
    li   t4, 10
    addi t0, a0, 1
    bgeu t0, a1, imm_loop
    lbu  t0, 0(a0)
    li   t1, 48
    bne  t0, t1, imm_loop
    lbu  t0, 1(a0)
    ori  t0, t0, 32
    li   t1, 120
    bne  t0, t1, imm_loop
    li   t4, 16
    addi a0, a0, 2
imm_loop:
    bgeu a0, a1, imm_fim
    lbu  t0, 0(a0)
    addi t3, t0, -48
    li   t1, 10
    bltu t3, t1, imm_conta
    li   t1, 16
    bne  t4, t1, imm_fim
    ori  t0, t0, 32
    addi t3, t0, -87
    li   t1, 10
    bltu t3, t1, imm_fim
    li   t1, 16
    bgeu t3, t1, imm_fim
imm_conta:
    mulhu t1, t2, t4
    bnez t1, imm_grande
    mul  t2, t2, t4
    add  t2, t2, t3
    bltu t2, t3, imm_grande
    addi t5, t5, 1
    addi a0, a0, 1
    j    imm_loop
imm_fim:
    beqz t5, imm_erro
    li   t1, 10
    bne  t4, t1, imm_sinal
    bnez t6, imm_negativo
    bltz t2, imm_grande
    j    imm_sinal
imm_negativo:
    li   t1, 0x80000000
    bltu t1, t2, imm_grande
imm_sinal:
    beqz t6, imm_ok
    neg  t2, t2
imm_ok:
    mv   a1, t2
    li   a2, 0
    j    imm_sai
imm_grande:
    li   a1, 0
    li   a2, 2
    j    imm_sai
imm_erro:
    li   a1, 0
    li   a2, 1
imm_sai:
    lw   ra, 12(sp)
    addi sp, sp, 16
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
