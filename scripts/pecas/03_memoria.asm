# Peca 3 - operando de memoria imm(reg)
# Rotinas copiadas do main.asm: skip_ws, scan_ident, lookup, parse_xnum, parse_reg, parse_imm, expect_char, parse_mem.
# Usado por lw/lhu/jalr (loads) e sw (stores): "8(sp)" vira imediato 8 e registrador base 2.
# O imediato e opcional ("(a0)" = 0) e precisa caber em 12 bits (-2048..2047).
# Status (a3): 0 ok, 1 imediato invalido, 2 fora de 12 bits, 3 faltou parentese, 4 registrador invalido.
# Cada caso: texto, imediato, registrador, status.

.data
regnames:
    .asciz "zero"
    .align 3
    .asciz "ra"
    .align 3
    .asciz "sp"
    .align 3
    .asciz "gp"
    .align 3
    .asciz "tp"
    .align 3
    .asciz "t0"
    .align 3
    .asciz "t1"
    .align 3
    .asciz "t2"
    .align 3
    .asciz "s0"
    .align 3
    .asciz "fp"
    .align 3
    .asciz "s1"
    .align 3
    .asciz "a0"
    .align 3
    .asciz "a1"
    .align 3
    .asciz "a2"
    .align 3
    .asciz "a3"
    .align 3
    .asciz "a4"
    .align 3
    .asciz "a5"
    .align 3
    .asciz "a6"
    .align 3
    .asciz "a7"
    .align 3
    .asciz "s2"
    .align 3
    .asciz "s3"
    .align 3
    .asciz "s4"
    .align 3
    .asciz "s5"
    .align 3
    .asciz "s6"
    .align 3
    .asciz "s7"
    .align 3
    .asciz "s8"
    .align 3
    .asciz "s9"
    .align 3
    .asciz "s10"
    .align 3
    .asciz "s11"
    .align 3
    .asciz "t3"
    .align 3
    .asciz "t4"
    .align 3
    .asciz "t5"
    .align 3
    .asciz "t6"
    .align 3
regnums: .byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31
.align 2
casos:
    .word c0
    .word 4
    .word 2
    .word 0
    .word c1
    .word 0
    .word 10
    .word 0
    .word c2
    .word -8
    .word 8
    .word 0
    .word c3
    .word 16
    .word 6
    .word 0
    .word c4
    .word 2047
    .word 5
    .word 0
    .word c5
    .word -2048
    .word 11
    .word 0
    .word c6
    .word 0
    .word 0
    .word 2
    .word c7
    .word 0
    .word 0
    .word 3
    .word c8
    .word 0
    .word 0
    .word 3
    .word c9
    .word 0
    .word 0
    .word 4
    .word c10
    .word 0
    .word 0
    .word 1
    .word 0
c0: .asciz "4(sp)"
c1: .asciz "(a0)"
c2: .asciz "-8(s0)"
c3: .asciz "0x10(t1)"
c4: .asciz "2047(x5)"
c5: .asciz "-2048(a1)"
c6: .asciz "2048(t0)"
c7: .asciz "4 sp"
c8: .asciz "4(sp"
c9: .asciz "4(t9)"
c10: .asciz "abc(t0)"
t_obtido:   .asciz "  obtido="
t_esperado: .asciz "  esperado="
t_seta:     .asciz "  -> "
t_ok:       .asciz "OK"
t_erro:     .asciz "ERRO"
t_nl:       .asciz "\n"
d_imm: .asciz "  imediato"
d_reg: .asciz "  registrador"
d_st:  .asciz "  status"

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
    call parse_mem
    mv   s3, a1
    mv   s4, a2
    mv   s5, a3
    mv   a0, s1
    li   a7, 4
    ecall
    la   a0, t_nl
    ecall
    mv   a0, s5
    lw   a1, 12(s0)
    la   a2, d_st
    call confere
    bnez s5, proximo
    mv   a0, s3
    lw   a1, 4(s0)
    la   a2, d_imm
    call confere
    mv   a0, s4
    lw   a1, 8(s0)
    la   a2, d_reg
    call confere
proximo:
    addi s0, s0, 16
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

scan_ident:
    bgeu a0, a1, scan_ident_ret
    lbu  t0, 0(a0)
    li   t1, 95
    beq  t0, t1, scan_ident_next
    li   t1, 46
    beq  t0, t1, scan_ident_next
    li   t1, 36
    beq  t0, t1, scan_ident_next
    addi t2, t0, -48
    li   t1, 10
    bltu t2, t1, scan_ident_next
    ori  t2, t0, 32
    addi t2, t2, -97
    li   t1, 26
    bltu t2, t1, scan_ident_next
scan_ident_ret:
    ret
scan_ident_next:
    addi a0, a0, 1
    j    scan_ident

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

parse_xnum:
    li   t0, 2
    blt  a1, t0, xnum_no
    li   t0, 3
    blt  t0, a1, xnum_no
    lbu  t0, 0(a0)
    li   t1, 120
    bne  t0, t1, xnum_no
    li   t2, 0
    li   t3, 1
xnum_loop:
    bgeu t3, a1, xnum_check
    add  t4, a0, t3
    lbu  t4, 0(t4)
    addi t4, t4, -48
    li   t5, 10
    bgeu t4, t5, xnum_no
    mul  t2, t2, t5
    add  t2, t2, t4
    addi t3, t3, 1
    j    xnum_loop
xnum_check:
    li   t5, 32
    bgeu t2, t5, xnum_no
    mv   a0, t2
    ret
xnum_no:
    li   a0, -1
    ret

parse_reg:
    addi sp, sp, -16
    sw   ra, 12(sp)
    call skip_ws
    sw   a0, 4(sp)
    call scan_ident
    sw   a0, 8(sp)
    lw   t0, 4(sp)
    sub  a1, a0, t0
    mv   a0, t0
    call parse_xnum
    bgez a0, parse_reg_ok
    lw   a0, 4(sp)
    lw   t0, 8(sp)
    sub  a1, t0, a0
    beqz a1, parse_reg_bad
    la   a2, regnames
    li   a3, 33
    call lookup
    bltz a0, parse_reg_bad
    la   t0, regnums
    add  t0, t0, a0
    lbu  a0, 0(t0)
parse_reg_ok:
    mv   a1, a0
    lw   a0, 8(sp)
    j    parse_reg_ret
parse_reg_bad:
    li   a1, -1
    lw   a0, 8(sp)
parse_reg_ret:
    lw   ra, 12(sp)
    addi sp, sp, 16
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

expect_char:
    addi sp, sp, -16
    sw   ra, 12(sp)
    call skip_ws
    bgeu a0, a1, expect_char_bad
    lbu  t0, 0(a0)
    bne  t0, a2, expect_char_bad
    addi a0, a0, 1
    li   a1, 0
    j    expect_char_ret
expect_char_bad:
    li   a1, -1
expect_char_ret:
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

parse_mem:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   a1, 4(sp)
    sw   zero, 8(sp)
    call skip_ws
    bgeu a0, a1, mem_erro1
    lbu  t0, 0(a0)
    li   t1, 40
    beq  t0, t1, mem_abre
    lw   a1, 4(sp)
    call parse_imm
    bnez a2, mem_erro_imm
    addi t0, a1, 1024
    addi t0, t0, 1024
    li   t1, 4096
    bgeu t0, t1, mem_erro2
    sw   a1, 8(sp)
mem_abre:
    lw   a1, 4(sp)
    li   a2, 40
    call expect_char
    bltz a1, mem_erro3
    lw   a1, 4(sp)
    call parse_reg
    bltz a1, mem_erro4
    sw   a1, 0(sp)
    lw   a1, 4(sp)
    li   a2, 41
    call expect_char
    bltz a1, mem_erro3
    lw   a1, 8(sp)
    lw   a2, 0(sp)
    li   a3, 0
    j    mem_sai
mem_erro_imm:
    mv   a3, a2
    j    mem_falha
mem_erro1:
    li   a3, 1
    j    mem_falha
mem_erro2:
    li   a3, 2
    j    mem_falha
mem_erro3:
    li   a3, 3
    j    mem_falha
mem_erro4:
    li   a3, 4
mem_falha:
    li   a1, 0
    li   a2, 0
mem_sai:
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
