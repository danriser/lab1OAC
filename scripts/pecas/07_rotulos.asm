# Peca 7 - tabela de rotulos e deslocamento
# Rotinas copiadas do main.asm: find_label, define_label, report_error.
# beq, bne e jal precisam do endereco de um rotulo que pode estar mais abaixo no arquivo. Por isso o main
# le o arquivo duas vezes: na passada 1 (pass = 1) so anota onde cada rotulo esta (define_label);
# na passada 2 usa a tabela (find_label) para calcular  deslocamento = endereco do rotulo - endereco da instrucao.
# Endereco no .text: 0x00400000 + 4 * indice da instrucao. s5 = indice da instrucao atual, s3 = secao.
# Aqui: define 'loop' na instrucao 2 e 'fim' na instrucao 5, depois calcula o deslocamento de um beq.

.data
msg_line:    .asciz "Erro na linha "
msg_colon:   .asciz ": "
msg_nl:      .asciz "\n"
e_dup:       .asciz "rotulo ja definido"
e_llong:     .asciz "rotulo longo demais (maximo 31 caracteres)"
e_lfull:     .asciz "tabela de rotulos cheia (maximo 256)"
datalen: .word 0
pass:    .word 0
lblcount: .word 0
lbladdr: .space 1024
lblnames: .space 8192
t_obtido:   .asciz "  obtido="
t_esperado: .asciz "  esperado="
t_seta:     .asciz "  -> "
t_ok:       .asciz "OK"
t_erro:     .asciz "ERRO"
t_nl:       .asciz "\n"
n_loop: .asciz "loop"
n_fim:  .asciz "fim"
n_nada: .asciz "nada"
d_end1: .asciz "endereco de loop (0x00400008)"
d_idx2: .asciz "indice de fim na tabela"
d_off:  .asciz "deslocamento de beq na instrucao 4 ate fim (instr. 5): +4"
d_ind:  .asciz "rotulo inexistente devolve -1"
d_dup:  .asciz "rotulo repetido nao entra de novo: total na tabela"

.text
main:
    li   t0, 1
    la   t1, pass
    sw   t0, 0(t1)
    li   s2, 1
    li   s4, 0
    li   s3, 0
    li   s5, 2
    la   a0, n_loop
    li   a1, 4
    call define_label
    li   s5, 5
    la   a0, n_fim
    li   a1, 3
    call define_label

    la   a0, n_loop
    li   a1, 4
    call find_label
    mv   s6, a0
    slli t0, a0, 2
    la   t1, lbladdr
    add  t1, t1, t0
    lw   a0, 0(t1)
    li   a1, 0x00400008
    la   a2, d_end1
    call confere_hex

    la   a0, n_fim
    li   a1, 3
    call find_label
    mv   s7, a0
    li   a1, 1
    la   a2, d_idx2
    call confere

    slli t0, s7, 2
    la   t1, lbladdr
    add  t1, t1, t0
    lw   t1, 0(t1)
    li   s5, 4
    slli t2, s5, 2
    li   t3, 0x00400000
    add  t2, t2, t3
    sub  a0, t1, t2
    li   a1, 4
    la   a2, d_off
    call confere

    la   a0, n_nada
    li   a1, 4
    call find_label
    li   a1, -1
    la   a2, d_ind
    call confere

    li   s5, 9
    la   a0, n_loop
    li   a1, 4
    call define_label
    la   t0, lblcount
    lw   a0, 0(t0)
    li   a1, 2
    la   a2, d_dup
    call confere
    li   a7, 10
    ecall
report_error:
    la   t1, pass
    lw   t1, 0(t1)
    li   t2, 1
    bne  t1, t2, report_error_now
    ret
report_error_now:
    mv   t0, a0
    la   a0, msg_line
    li   a7, 4
    ecall
    mv   a0, s2
    li   a7, 1
    ecall
    la   a0, msg_colon
    li   a7, 4
    ecall
    mv   a0, t0
    li   a7, 4
    ecall
    la   a0, msg_nl
    li   a7, 4
    ecall
    addi s4, s4, 1
    ret

find_label:
    la   t0, lblcount
    lw   t0, 0(t0)
    li   t1, 0
fl_loop:
    bgeu t1, t0, fl_none
    slli t2, t1, 5
    la   t3, lblnames
    add  t3, t3, t2
    li   t4, 0
fl_cmp:
    bgeu t4, a1, fl_tail
    add  t5, a0, t4
    lbu  t5, 0(t5)
    add  t6, t3, t4
    lbu  t6, 0(t6)
    bne  t5, t6, fl_next
    addi t4, t4, 1
    j    fl_cmp
fl_tail:
    add  t6, t3, a1
    lbu  t6, 0(t6)
    beqz t6, fl_found
fl_next:
    addi t1, t1, 1
    j    fl_loop
fl_found:
    mv   a0, t1
    ret
fl_none:
    li   a0, -1
    ret

define_label:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   a0, 8(sp)
    sw   a1, 4(sp)
    la   t0, pass
    lw   t0, 0(t0)
    li   t1, 1
    bne  t0, t1, dl_ret
    li   t0, 31
    bltu t0, a1, dl_long
    call find_label
    bgez a0, dl_dup
    la   t0, lblcount
    lw   t1, 0(t0)
    li   t2, 256
    bgeu t1, t2, dl_full
    slli t2, t1, 5
    la   t3, lblnames
    add  t3, t3, t2
    lw   a0, 8(sp)
    lw   a1, 4(sp)
    li   t4, 0
dl_copy:
    bgeu t4, a1, dl_copied
    add  t5, a0, t4
    lbu  t5, 0(t5)
    add  t6, t3, t4
    sb   t5, 0(t6)
    addi t4, t4, 1
    j    dl_copy
dl_copied:
    add  t6, t3, a1
    sb   zero, 0(t6)
    beqz s3, dl_text
    li   t4, 0x10010000
    la   t5, datalen
    lw   t5, 0(t5)
    add  t4, t4, t5
    j    dl_store
dl_text:
    slli t4, s5, 2
    li   t5, 0x00400000
    add  t4, t4, t5
dl_store:
    slli t2, t1, 2
    la   t3, lbladdr
    add  t3, t3, t2
    sw   t4, 0(t3)
    addi t1, t1, 1
    sw   t1, 0(t0)
    j    dl_ret
dl_dup:
    la   a0, e_dup
    j    dl_err
dl_long:
    la   a0, e_llong
    j    dl_err
dl_full:
    la   a0, e_lfull
dl_err:
    call report_error_now
dl_ret:
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
