# Peca 6 - escrever a linha do .mif
# Rotinas copiadas do main.asm: put_str, put_range, put_hex8, put_dec.
# O .mif e um arquivo de texto. Cada instrucao vira uma linha:  INDICE : PALAVRA;   % N: linha original %
# put_hex8 escreve 8 digitos hexa (minusculos), put_dec escreve o numero da linha em decimal,
# put_str copia um texto fixo e put_range copia a linha original do .asm.
# Todas recebem o destino em a0 e devolvem o novo destino em a0.

.data
t_obtido:   .asciz "  obtido="
t_esperado: .asciz "  esperado="
t_seta:     .asciz "  -> "
t_ok:       .asciz "OK"
t_erro:     .asciz "ERRO"
t_nl:       .asciz "\n"
sep1: .asciz " : "
sep2: .asciz ";   % "
sep3: .asciz ": "
sep4: .asciz " %\n"
original: .asciz "lw t2, 0(t1)"
esperada: .asciz "00000003 : 00032383;   % 12: lw t2, 0(t1) %\n"
d_linha: .asciz "linha do MIF igual a do arquivo de referencia (1 = sim)"
d_hex: .asciz "put_hex8 de 0xDEADBEEF (primeiro digito d = 100)"
d_dec: .asciz "put_dec de 1405 escreve 4 digitos"
saida: .space 128
saida2: .space 32

.text
main:
    la   a0, saida
    li   a1, 3
    call put_hex8
    la   a1, sep1
    call put_str
    li   a1, 0x00032383
    call put_hex8
    la   a1, sep2
    call put_str
    li   a1, 12
    call put_dec
    la   a1, sep3
    call put_str
    la   a1, original
    la   a2, original
    addi a2, a2, 12
    call put_range
    la   a1, sep4
    call put_str
    sb   zero, 0(a0)
    la   a0, saida
    li   a7, 4
    ecall
    la   a0, saida
    la   a1, esperada
    call igual
    li   a1, 1
    la   a2, d_linha
    call confere

    la   a0, saida2
    li   a1, 0xDEADBEEF
    call put_hex8
    sb   zero, 0(a0)
    la   t0, saida2
    lbu  a0, 0(t0)
    li   a1, 100
    la   a2, d_hex
    call confere

    la   a0, saida2
    li   a1, 1405
    call put_dec
    la   t0, saida2
    sub  a0, a0, t0
    li   a1, 4
    la   a2, d_dec
    call confere
    li   a7, 10
    ecall

# igual(a0, a1) -> a0 = 1 se os dois textos sao iguais
igual:
    lbu  t0, 0(a0)
    lbu  t1, 0(a1)
    bne  t0, t1, igual_nao
    beqz t0, igual_sim
    addi a0, a0, 1
    addi a1, a1, 1
    j    igual
igual_sim:
    li   a0, 1
    ret
igual_nao:
    li   a0, 0
    ret
put_str:
    lbu  t0, 0(a1)
    beqz t0, put_str_ret
    sb   t0, 0(a0)
    addi a0, a0, 1
    addi a1, a1, 1
    j    put_str
put_str_ret:
    ret

put_range:
    bgeu a1, a2, put_range_ret
    lbu  t0, 0(a1)
    sb   t0, 0(a0)
    addi a0, a0, 1
    addi a1, a1, 1
    j    put_range
put_range_ret:
    ret

put_hex8:
    li   t0, 28
put_hex8_loop:
    srl  t1, a1, t0
    andi t1, t1, 15
    li   t2, 10
    blt  t1, t2, put_hex8_digit
    addi t1, t1, 87
    j    put_hex8_store
put_hex8_digit:
    addi t1, t1, 48
put_hex8_store:
    sb   t1, 0(a0)
    addi a0, a0, 1
    addi t0, t0, -4
    bgez t0, put_hex8_loop
    ret

put_dec:
    li   t0, 10
    li   t2, 1
put_dec_pow:
    divu t3, a1, t2
    bltu t3, t0, put_dec_digits
    mul  t2, t2, t0
    j    put_dec_pow
put_dec_digits:
    divu t3, a1, t2
    addi t4, t3, 48
    sb   t4, 0(a0)
    addi a0, a0, 1
    remu a1, a1, t2
    li   t5, 1
    beq  t2, t5, put_dec_ret
    divu t2, t2, t0
    j    put_dec_digits
put_dec_ret:
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
