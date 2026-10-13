# Peca 1 - ler um registrador
# Rotinas copiadas do main.asm: lookup, parse_xnum, parse_reg (usa skip_ws e scan_ident).
# O registrador pode vir como x0..x31 (parse_xnum) ou pelo nome ABI (zero, ra, sp, t0, a0...).
# Para os nomes, lookup procura o texto numa tabela (regnames) e regnums diz o numero do registrador.
# Cada caso: texto, numero esperado (-1 = registrador invalido).

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
    .word 5
    .word c1
    .word 31
    .word c2
    .word 0
    .word c3
    .word 8
    .word c4
    .word 8
    .word c5
    .word 27
    .word c6
    .word 17
    .word c7
    .word 0
    .word c8
    .word -1
    .word c9
    .word -1
    .word c10
    .word -1
    .word 0
c0: .asciz "t0"
c1: .asciz "x31"
c2: .asciz "zero"
c3: .asciz "fp"
c4: .asciz "s0"
c5: .asciz "s11"
c6: .asciz "a7"
c7: .asciz "x0"
c8: .asciz "x32"
c9: .asciz "foo"
c10: .asciz "t7"
t_obtido:   .asciz "  obtido="
t_esperado: .asciz "  esperado="
t_seta:     .asciz "  -> "
t_ok:       .asciz "OK"
t_erro:     .asciz "ERRO"
t_nl:       .asciz "\n"

.text
main:
    la   s0, casos
caso:
    lw   s1, 0(s0)
    beqz s1, fim
    lw   s2, 4(s0)
    mv   a0, s1
    call tam_str
    add  a1, s1, a0
    mv   a0, s1
    call parse_reg
    mv   a0, a1
    mv   a1, s2
    mv   a2, s1
    call confere
    addi s0, s0, 8
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
