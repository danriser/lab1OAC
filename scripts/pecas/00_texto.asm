# Peca 0 - andar pelo texto da linha
# Rotinas copiadas do main.asm: find_eol, skip_ws, trim_end, scan_ident.
# O montador le o arquivo inteiro como uma sequencia de bytes. Para traduzir uma linha ele precisa:
#   find_eol    achar onde a linha termina ('\n')
#   skip_ws     pular espacos e tabs
#   trim_end    ignorar espacos no final
#   scan_ident  ler um nome (mnemonico, registrador, rotulo): letras, digitos, '_', '.', '$'

.data
linha1: .asciz "add t0, t1\nsub t2, t3"
linha2: .asciz "   addi t0, t0, 1   "
linha3: .asciz "loop: lw t0, 0(sp)"
t_obtido:   .asciz "  obtido="
t_esperado: .asciz "  esperado="
t_seta:     .asciz "  -> "
t_ok:       .asciz "OK"
t_erro:     .asciz "ERRO"
t_nl:       .asciz "\n"

.text
main:
    la   a0, linha1
    call find_eol
    la   t0, linha1
    sub  a0, a0, t0
    li   a1, 10
    la   a2, d_eol
    call confere

    la   a0, linha2
    la   t0, linha2
    call tam_str
    la   a1, linha2
    add  a1, a1, a0
    la   a0, linha2
    call skip_ws
    la   t0, linha2
    sub  a0, a0, t0
    li   a1, 3
    la   a2, d_ws
    call confere

    la   a0, linha2
    call tam_str
    la   a1, linha2
    add  a1, a1, a0
    la   a0, linha2
    call trim_end
    la   t0, linha2
    sub  a0, a1, t0
    li   a1, 17
    la   a2, d_trim
    call confere

    la   a0, linha3
    call tam_str
    la   a1, linha3
    add  a1, a1, a0
    la   a0, linha3
    call scan_ident
    la   t0, linha3
    sub  a0, a0, t0
    li   a1, 4
    la   a2, d_ident
    call confere

    li   a7, 10
    ecall

.data
d_eol:   .asciz "find_eol: posicao do fim da primeira linha"
d_ws:    .asciz "skip_ws: espacos pulados no inicio"
d_trim:  .asciz "trim_end: tamanho sem os espacos finais"
d_ident: .asciz "scan_ident: tamanho do primeiro nome (loop)"
.text
find_eol:
    lbu  t0, 0(a0)
    beqz t0, find_eol_ret
    li   t1, 10
    beq  t0, t1, find_eol_ret
    addi a0, a0, 1
    j    find_eol
find_eol_ret:
    ret

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

trim_end:
    bgeu a0, a1, trim_end_ret
    lbu  t0, -1(a1)
    li   t1, 32
    beq  t0, t1, trim_end_cut
    li   t1, 9
    beq  t0, t1, trim_end_cut
    li   t1, 13
    bne  t0, t1, trim_end_ret
trim_end_cut:
    addi a1, a1, -1
    j    trim_end
trim_end_ret:
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
