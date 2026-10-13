# Peca 8 - secao .data (little-endian)
# Rotinas copiadas do main.asm: skip_ws, parse_imm, expect_char, emit_byte, align_data, data_dir.
# As diretivas da .data viram bytes num vetor (databuf), na ordem em que aparecem. O _data.mif mostra esse
# vetor em palavras de 4 bytes, com o byte menos significativo primeiro (little-endian), igual ao RARS.
#   .word alinha em 4 bytes e guarda 4 bytes por valor    .half alinha em 2 e guarda 2 bytes
#   .byte guarda 1 byte                                   .asciz/.string guardam os caracteres e um 0 no fim
# Indices de diretiva em data_dir: 4 .word, 5 .half, 6 .byte, 7 .asciz, 8 .string, 9 .ascii, 10 .space.
# O exemplo reproduz o inicio do exemplo-lab1 do Aprender3 (.word 1,2 / .half 7,6,5 / .byte 6,5,4 / .string).

.data
datalen: .word 0
.align 2
databuf: .space 4096
t_obtido:   .asciz "  obtido="
t_esperado: .asciz "  esperado="
t_seta:     .asciz "  -> "
t_ok:       .asciz "OK"
t_erro:     .asciz "ERRO"
t_nl:       .asciz "\n"
txt1: .asciz " 1, 2"
txt2: .asciz " 7, 6, 5"
txt3: .asciz " 6, 5, 4"
txt4: .asciz " \"ab\""
txt5: .asciz " 300"
d_w0: .asciz "palavra 0 (.word 1)"
d_w1: .asciz "palavra 1 (.word 2)"
d_w2: .asciz "palavra 2 (.half 7,6)"
d_w3: .asciz "palavra 3 (bytes 05 00 06 05: .half 5 e .byte 6,5)"
d_w4: .asciz "palavra 4 (bytes 04 61 62 00: .byte 4 e a string ab com zero final)"
d_w5: .asciz "palavra 5 (resto do vetor, zerado)"
d_st: .asciz "status de .byte 300 (2 = fora do intervalo)"

.text
main:
    li   a0, 4
    la   a1, txt1
    call fim_do_texto
    call data_dir
    li   a0, 5
    la   a1, txt2
    call fim_do_texto
    call data_dir
    li   a0, 6
    la   a1, txt3
    call fim_do_texto
    call data_dir
    li   a0, 8
    la   a1, txt4
    call fim_do_texto
    call data_dir

    la   s0, databuf
    lw   a0, 0(s0)
    li   a1, 0x00000001
    la   a2, d_w0
    call confere_hex
    lw   a0, 4(s0)
    li   a1, 0x00000002
    la   a2, d_w1
    call confere_hex
    lw   a0, 8(s0)
    li   a1, 0x00060007
    la   a2, d_w2
    call confere_hex
    lw   a0, 12(s0)
    li   a1, 0x05060005
    la   a2, d_w3
    call confere_hex
    lw   a0, 16(s0)
    li   a1, 0x00626104
    la   a2, d_w4
    call confere_hex
    lw   a0, 20(s0)
    li   a1, 0x00000000
    la   a2, d_w5
    call confere_hex

    li   a0, 6
    la   a1, txt5
    call fim_do_texto
    call data_dir
    li   a1, 2
    la   a2, d_st
    call confere
    li   a7, 10
    ecall

# fim_do_texto(a1 = texto) -> a2 = fim do texto (a0 e a1 ficam como estao)
fim_do_texto:
    mv   a2, a1
fim_do_texto_loop:
    lbu  t0, 0(a2)
    beqz t0, fim_do_texto_ret
    addi a2, a2, 1
    j    fim_do_texto_loop
fim_do_texto_ret:
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

emit_byte:
    la   t0, datalen
    lw   t1, 0(t0)
    li   t2, 4096
    bgeu t1, t2, emit_byte_full
    la   t2, databuf
    add  t2, t2, t1
    sb   a0, 0(t2)
    addi t1, t1, 1
    sw   t1, 0(t0)
    li   a0, 0
    ret
emit_byte_full:
    li   a0, -1
    ret

align_data:
    la   t0, datalen
    lw   t1, 0(t0)
    addi t2, a0, -1
    add  t1, t1, t2
    not  t3, t2
    and  t1, t1, t3
    li   t4, 4096
    bltu t4, t1, align_data_full
    sw   t1, 0(t0)
    li   a0, 0
    ret
align_data_full:
    li   a0, -1
    ret

data_dir:
    addi sp, sp, -32
    sw   ra, 28(sp)
    sw   s7, 24(sp)
    sw   s8, 20(sp)
    sw   s9, 16(sp)
    sw   s10, 12(sp)
    mv   s9, a0
    mv   s7, a1
    mv   s8, a2
    li   t0, 7
    bgeu s9, t0, dd_text
    li   s10, 4
    li   t0, 4
    beq  s9, t0, dd_align
    li   s10, 2
    li   t0, 5
    beq  s9, t0, dd_align
    li   s10, 1
    j    dd_num_loop
dd_align:
    mv   a0, s10
    call align_data
    bltz a0, dd_full
dd_num_loop:
    mv   a0, s7
    mv   a1, s8
    call parse_imm
    mv   s7, a0
    li   t0, 1
    beq  a2, t0, dd_bad
    li   t0, 2
    beq  a2, t0, dd_range
    li   t0, 4
    beq  s10, t0, dd_emit
    li   t0, 1
    bne  s10, t0, dd_chk_half
    addi t1, a1, 128
    li   t2, 384
    bgeu t1, t2, dd_range
    j    dd_emit
dd_chk_half:
    li   t3, 32768
    add  t1, a1, t3
    li   t2, 98304
    bgeu t1, t2, dd_range
dd_emit:
    sw   a1, 8(sp)
    sw   zero, 4(sp)
dd_emit_loop:
    lw   t0, 4(sp)
    bgeu t0, s10, dd_emit_done
    lw   t1, 8(sp)
    slli t2, t0, 3
    srl  a0, t1, t2
    andi a0, a0, 255
    call emit_byte
    bltz a0, dd_full
    lw   t0, 4(sp)
    addi t0, t0, 1
    sw   t0, 4(sp)
    j    dd_emit_loop
dd_emit_done:
    mv   a0, s7
    mv   a1, s8
    call skip_ws
    mv   s7, a0
    bgeu s7, s8, dd_ok
    lbu  t0, 0(s7)
    li   t1, 44
    bne  t0, t1, dd_sep
    addi s7, s7, 1
    j    dd_num_loop

dd_text:
    li   t0, 10
    beq  s9, t0, dd_space
    mv   a0, s7
    mv   a1, s8
    li   a2, 34
    call expect_char
    bltz a1, dd_strerr
    mv   s7, a0
dd_str_loop:
    bgeu s7, s8, dd_strerr
    lbu  t0, 0(s7)
    li   t1, 34
    beq  t0, t1, dd_str_end
    li   t1, 92
    bne  t0, t1, dd_str_put
    addi s7, s7, 1
    bgeu s7, s8, dd_strerr
    lbu  t0, 0(s7)
    li   t1, 110
    beq  t0, t1, dd_esc_n
    li   t1, 116
    beq  t0, t1, dd_esc_t
    li   t1, 114
    beq  t0, t1, dd_esc_r
    li   t1, 48
    beq  t0, t1, dd_esc_0
    li   t1, 92
    beq  t0, t1, dd_str_put
    li   t1, 34
    beq  t0, t1, dd_str_put
    j    dd_strerr
dd_esc_n:
    li   t0, 10
    j    dd_str_put
dd_esc_t:
    li   t0, 9
    j    dd_str_put
dd_esc_r:
    li   t0, 13
    j    dd_str_put
dd_esc_0:
    li   t0, 0
dd_str_put:
    mv   a0, t0
    call emit_byte
    bltz a0, dd_full
    addi s7, s7, 1
    j    dd_str_loop
dd_str_end:
    addi s7, s7, 1
    li   t0, 9
    beq  s9, t0, dd_str_tail
    li   a0, 0
    call emit_byte
    bltz a0, dd_full
dd_str_tail:
    mv   a0, s7
    mv   a1, s8
    call skip_ws
    bne  a0, s8, dd_extra
    j    dd_ok

dd_space:
    mv   a0, s7
    mv   a1, s8
    call parse_imm
    mv   s7, a0
    li   t0, 1
    beq  a2, t0, dd_bad
    li   t0, 2
    beq  a2, t0, dd_range
    bltz a1, dd_range
    li   t0, 4096
    bltu t0, a1, dd_full
    mv   s10, a1
dd_space_loop:
    beqz s10, dd_space_end
    li   a0, 0
    call emit_byte
    bltz a0, dd_full
    addi s10, s10, -1
    j    dd_space_loop
dd_space_end:
    mv   a0, s7
    mv   a1, s8
    call skip_ws
    bne  a0, s8, dd_extra
dd_ok:
    li   a0, 0
    j    dd_ret
dd_bad:
    li   a0, 1
    j    dd_ret
dd_range:
    li   a0, 2
    j    dd_ret
dd_sep:
    li   a0, 3
    j    dd_ret
dd_full:
    li   a0, 4
    j    dd_ret
dd_strerr:
    li   a0, 5
    j    dd_ret
dd_extra:
    li   a0, 6
dd_ret:
    lw   ra, 28(sp)
    lw   s7, 24(sp)
    lw   s8, 20(sp)
    lw   s9, 16(sp)
    lw   s10, 12(sp)
    addi sp, sp, 32
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
