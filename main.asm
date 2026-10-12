# Montador RISC-V RV32I -> .mif (RARS 1.6)

.data
prompt:      .asciz "Arquivo .asm de entrada: "
msg_line:    .asciz "Erro na linha "
msg_colon:   .asciz ": "
msg_nl:      .asciz "\n"
msg_open:    .asciz "Erro: nao foi possivel abrir o arquivo de entrada.\n"
msg_noname:  .asciz "Erro: nome de arquivo vazio.\n"
msg_big:     .asciz "Erro: arquivo de entrada maior que 65000 bytes.\n"
msg_create:  .asciz "Erro: nao foi possivel criar o arquivo de saida.\n"
msg_write:   .asciz "Erro: falha ao gravar o arquivo de saida.\n"
msg_fail:    .asciz "Montagem abortada. Quantidade de erros: "
e_inst:      .asciz "instrucao desconhecida ou nao suportada (veja a lista no cabecalho do main.asm)"
e_reg:       .asciz "registrador invalido"
e_sep:       .asciz "esperada virgula entre os operandos"
e_extra:     .asciz "texto sobrando depois do ultimo operando"
e_dir:       .asciz "diretiva nao suportada"
e_label:     .asciz "rotulo vazio antes de ':'"
e_full:      .asciz "memoria de saida esgotada"
e_depth:     .asciz "programa maior que 16384 instrucoes (DEPTH do MIF)"
e_imm:       .asciz "imediato invalido ou ausente (aceito: decimal, negativo ou 0xHHHHHHHH)"
e_range:     .asciz "imediato fora do intervalo de 12 bits (-2048 a 2047)"
e_mem:       .asciz "esperado o formato imediato(registrador), ex.: 4(sp)"
e_shamt:     .asciz "deslocamento fora do intervalo (0 a 31)"
e_drange:    .asciz "valor fora do intervalo do tipo da diretiva (.byte -128..255, .half -32768..65535)"
e_dfull:     .asciz "area .data maior que 4096 bytes (1024 palavras)"
e_dstr:      .asciz "string invalida (esperado texto entre aspas, escapes \\n \\t \\r \\0 \\\\ \\\")"
e_dtext:     .asciz "diretiva de dados fora da secao .data"
e_dline:     .asciz "na secao .data so sao aceitas diretivas (.word .half .byte .asciz .string .ascii .space)"
hdr:         .asciz "DEPTH = 16384;\nWIDTH = 32;\nADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\nCONTENT\nBEGIN\n"
dhdr:        .asciz "DEPTH = 32768;\nWIDTH = 32;\nADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\nCONTENT\nBEGIN\n"
ftr:         .asciz "END;\n"
suffix:      .asciz "_text.mif"
suffix2:     .asciz "_data.mif"
sep5:        .asciz ";\n"
sep1:        .asciz " : "
sep2:        .asciz ";   % "
sep3:        .asciz ": "
sep4:        .asciz " %\n"

.eqv N_INST, 28

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
fmttab:  .byte 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 3, 5, 5, 5
optab:   .byte 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x33, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x03, 0x03, 0x03, 0x03, 0x03, 0x67, 0x23, 0x23, 0x23
f3tab:   .byte 0, 0, 1, 2, 3, 4, 5, 5, 6, 7, 0, 2, 3, 4, 6, 7, 1, 5, 5, 0, 1, 2, 4, 5, 0, 0, 1, 2
f7tab:   .byte 0, 32, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0
.align 3
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
.align 3
dirnames:
    .asciz ".text"
    .align 3
    .asciz ".data"
    .align 3
    .asciz ".globl"
    .align 3
    .asciz ".global"
    .align 3
    .asciz ".word"
    .align 3
    .asciz ".half"
    .align 3
    .asciz ".byte"
    .align 3
    .asciz ".asciz"
    .align 3
    .asciz ".string"
    .align 3
    .asciz ".ascii"
    .align 3
    .asciz ".space"
    .align 3

.align 2
fname:   .space 260
outname: .space 330
outname2: .space 330
datalen: .word 0
databuf: .space 4096
inbuf:   .space 70000

.text
.globl main
main:
    blez a0, ask_name
    lw   t2, 0(a1)
    la   t3, fname
    li   t4, 255
copy_arg:
    lbu  t5, 0(t2)
    beqz t5, copy_arg_end
    beqz t4, copy_arg_end
    sb   t5, 0(t3)
    addi t2, t2, 1
    addi t3, t3, 1
    addi t4, t4, -1
    j    copy_arg
copy_arg_end:
    sb   zero, 0(t3)
    j    have_name

ask_name:
    la   a0, prompt
    li   a7, 4
    ecall
    la   a0, fname
    li   a1, 255
    li   a7, 8
    ecall
    la   t0, fname
strip_nl:
    lbu  t1, 0(t0)
    beqz t1, strip_done
    li   t2, 10
    beq  t1, t2, strip_cut
    li   t2, 13
    beq  t1, t2, strip_cut
    addi t0, t0, 1
    j    strip_nl
strip_cut:
    sb   zero, 0(t0)
strip_done:
    la   t0, fname
    lbu  t1, 0(t0)
    bnez t1, have_name
    la   a0, msg_noname
    j    fatal

have_name:
    la   a0, fname
    li   a1, 0
    li   a7, 1024
    ecall
    bltz a0, err_open
    mv   s0, a0
    la   s1, inbuf
    li   s2, 0
read_loop:
    li   t0, 65000
    bge  s2, t0, err_big
    mv   a0, s0
    mv   a1, s1
    li   a2, 4096
    li   a7, 63
    ecall
    blez a0, read_done
    add  s1, s1, a0
    add  s2, s2, a0
    j    read_loop
read_done:
    mv   a0, s0
    li   a7, 57
    ecall
    la   t0, inbuf
    add  t0, t0, s2
    sb   zero, 0(t0)

    la   t0, fname
    la   t1, outname
    li   t2, 0
name_copy:
    lbu  t3, 0(t0)
    beqz t3, name_end
    sb   t3, 0(t1)
    li   t4, 46
    bne  t3, t4, name_chk_sep
    mv   t2, t1
    j    name_adv
name_chk_sep:
    li   t4, 47
    beq  t3, t4, name_reset
    li   t4, 92
    bne  t3, t4, name_adv
name_reset:
    li   t2, 0
name_adv:
    addi t0, t0, 1
    addi t1, t1, 1
    j    name_copy
name_end:
    beqz t2, name_suffix
    mv   t1, t2
name_suffix:
    la   t0, suffix
name_suf_loop:
    lbu  t3, 0(t0)
    sb   t3, 0(t1)
    beqz t3, name_done
    addi t0, t0, 1
    addi t1, t1, 1
    j    name_suf_loop
name_done:
    la   t0, outname
    la   t2, outname2
name_copy2:
    lbu  t3, 0(t0)
    sb   t3, 0(t2)
    beqz t3, name_copy2_end
    addi t0, t0, 1
    addi t2, t2, 1
    j    name_copy2
name_copy2_end:
    addi t2, t2, -9
    la   t0, suffix2
name_suf2:
    lbu  t3, 0(t0)
    sb   t3, 0(t2)
    beqz t3, name_done2
    addi t0, t0, 1
    addi t2, t2, 1
    j    name_suf2
name_done2:

    li   a0, 524288
    li   a7, 9
    ecall
    mv   s8, a0
    mv   s1, a0
    li   t0, 524288
    add  s6, a0, t0
    mv   a0, s1
    la   a1, hdr
    call put_str
    mv   s1, a0

    li   s2, 0
    li   s3, 0
    li   s4, 0
    li   s5, 0
    la   s0, inbuf
line_loop:
    lbu  t0, 0(s0)
    beqz t0, lines_done
    addi s2, s2, 1
    mv   a0, s0
    call find_eol
    mv   s11, a0
    mv   a0, s0
    mv   a1, s11
    call process_line
    mv   s0, s11
    lbu  t0, 0(s0)
    beqz t0, lines_done
    addi s0, s0, 1
    j    line_loop

lines_done:
    bnez s4, finish_errors
    mv   a0, s1
    la   a1, ftr
    call put_str
    mv   s1, a0
    la   a0, outname
    mv   a1, s8
    sub  a2, s1, s8
    call write_file

    li   a0, 40000
    li   a7, 9
    ecall
    mv   s8, a0
    mv   s1, a0
    mv   a0, s1
    la   a1, dhdr
    call put_str
    mv   s1, a0
    li   s9, 0
data_words:
    mv   a0, s1
    mv   a1, s9
    call put_hex8
    la   a1, sep1
    call put_str
    la   t0, databuf
    slli t1, s9, 2
    add  t0, t0, t1
    lw   a1, 0(t0)
    call put_hex8
    la   a1, sep5
    call put_str
    mv   s1, a0
    addi s9, s9, 1
    li   t0, 1024
    bltu s9, t0, data_words
    mv   a0, s1
    la   a1, ftr
    call put_str
    mv   s1, a0
    la   a0, outname2
    mv   a1, s8
    sub  a2, s1, s8
    call write_file
    li   a0, 0
    li   a7, 93
    ecall

finish_errors:
    la   a0, msg_fail
    li   a7, 4
    ecall
    mv   a0, s4
    li   a7, 1
    ecall
    la   a0, msg_nl
    li   a7, 4
    ecall
    li   a0, 1
    li   a7, 93
    ecall

err_open:   la a0, msg_open
            j  fatal
err_big:    la a0, msg_big
            j  fatal
err_create: la a0, msg_create
            j  fatal
err_write:  la a0, msg_write
fatal:
    li   a7, 4
    ecall
    li   a0, 1
    li   a7, 93
    ecall

process_line:
    addi sp, sp, -48
    sw   ra, 44(sp)
    sw   s7, 40(sp)
    sw   s8, 36(sp)
    sw   s9, 32(sp)
    sw   s10, 28(sp)
    sw   a0, 4(sp)
    call trim_end
    sw   a1, 0(sp)
    mv   t0, a0
    li   t3, 0
cmt_loop:
    bgeu t0, a1, cmt_done
    lbu  t1, 0(t0)
    li   t2, 34
    bne  t1, t2, cmt_nq
    xori t3, t3, 1
    j    cmt_next
cmt_nq:
    li   t2, 92
    bne  t1, t2, cmt_nb
    beqz t3, cmt_next
    addi t0, t0, 1
    j    cmt_next
cmt_nb:
    li   t2, 35
    bnez t3, cmt_next
    beq  t1, t2, cmt_cut
cmt_next:
    addi t0, t0, 1
    j    cmt_loop
cmt_cut:
    mv   a1, t0
cmt_done:
    call skip_ws
    mv   s9, a0
    call trim_end
    mv   s10, a1
    bgeu s9, s10, pl_ret
    mv   s7, s9

    mv   a0, s7
    mv   a1, s10
    call scan_ident
    bgeu a0, s10, no_label
    lbu  t0, 0(a0)
    li   t1, 58
    bne  t0, t1, no_label
    beq  a0, s7, bad_label
    addi s7, a0, 1
    mv   a0, s7
    mv   a1, s10
    call skip_ws
    mv   s7, a0
    bgeu s7, s10, pl_ret
no_label:

    lbu  t0, 0(s7)
    li   t1, 46
    bne  t0, t1, not_dir
    mv   a0, s7
    mv   a1, s10
    call scan_ident
    sw   a0, 8(sp)
    sub  a1, a0, s7
    mv   a0, s7
    la   a2, dirnames
    li   a3, 11
    call lookup
    beqz a0, dir_text
    li   t0, 1
    beq  a0, t0, dir_data
    bltz a0, dir_unknown
    li   t0, 4
    blt  a0, t0, pl_ret
    beqz s3, bad_dtext
    lw   a1, 8(sp)
    mv   a2, s10
    call data_dir
    beqz a0, pl_ret
    li   t0, 1
    beq  a0, t0, bad_imm
    li   t0, 2
    beq  a0, t0, bad_drange
    li   t0, 3
    beq  a0, t0, bad_sep
    li   t0, 4
    beq  a0, t0, bad_dfull
    li   t0, 5
    beq  a0, t0, bad_dstr
    j    bad_extra
dir_unknown:
    la   a0, e_dir
    call report_error
    j    pl_ret
dir_text:
    li   s3, 0
    j    pl_ret
dir_data:
    li   s3, 1
    j    pl_ret
not_dir:
    bnez s3, bad_dline

    mv   a0, s7
    mv   a1, s10
    call scan_ident
    sw   a0, 8(sp)
    sub  a1, a0, s7
    beqz a1, bad_inst
    mv   a0, s7
    la   a2, instnames
    li   a3, N_INST
    call lookup
    bltz a0, bad_inst
    lw   s7, 8(sp)
    sw   a0, 24(sp)
    la   t0, fmttab
    add  t0, t0, a0
    lbu  t3, 0(t0)
    sw   t3, 20(sp)
    la   t0, optab
    add  t0, t0, a0
    lbu  t4, 0(t0)
    la   t0, f3tab
    add  t0, t0, a0
    lbu  t1, 0(t0)
    la   t0, f7tab
    add  t0, t0, a0
    lbu  t2, 0(t0)
    slli t1, t1, 12
    slli t2, t2, 25
    or   s8, t1, t2
    or   s8, s8, t4
    li   t0, 4
    beq  t3, t0, r_fmt
    li   t0, 5
    beq  t3, t0, s_fmt
    j    i_start

r_fmt:
    mv   a0, s7
    mv   a1, s10
    call parse_reg
    bltz a1, bad_reg
    slli t0, a1, 7
    or   s8, s8, t0
    mv   s7, a0
    mv   a0, s7
    mv   a1, s10
    li   a2, 44
    call expect_char
    bltz a1, bad_sep
    mv   s7, a0
    mv   a0, s7
    mv   a1, s10
    call parse_reg
    bltz a1, bad_reg
    slli t0, a1, 15
    or   s8, s8, t0
    mv   s7, a0
    mv   a0, s7
    mv   a1, s10
    li   a2, 44
    call expect_char
    bltz a1, bad_sep
    mv   s7, a0
    mv   a0, s7
    mv   a1, s10
    call parse_reg
    bltz a1, bad_reg
    slli t0, a1, 20
    or   s8, s8, t0
    mv   s7, a0
    j    i_finish

s_fmt:
    mv   a0, s7
    mv   a1, s10
    call parse_reg
    bltz a1, bad_reg
    slli t0, a1, 20
    or   s8, s8, t0
    mv   s7, a0
    mv   a0, s7
    mv   a1, s10
    li   a2, 44
    call expect_char
    bltz a1, bad_sep
    mv   s7, a0
    mv   a0, s7
    mv   a1, s10
    call parse_mem
    mv   s7, a0
    bnez a3, i_mem_err
    slli t0, a2, 15
    or   s8, s8, t0
    andi t0, a1, 31
    slli t0, t0, 7
    or   s8, s8, t0
    srai t0, a1, 5
    slli t0, t0, 25
    or   s8, s8, t0
    j    i_finish

i_start:
    mv   a0, s7
    mv   a1, s10
    call parse_reg
    bltz a1, bad_reg
    slli t0, a1, 7
    or   s8, s8, t0
    mv   s7, a0
    lw   t3, 20(sp)
    li   t4, 3
    bne  t3, t4, i_comma
    mv   a0, s7
    mv   a1, s10
    call skip_ws
    bltu a0, s10, i_comma
    srli t0, s8, 7
    andi t0, t0, 31
    li   t1, 0xFFFFF07F
    and  s8, s8, t1
    ori  s8, s8, 128
    slli t0, t0, 15
    or   s8, s8, t0
    j    i_finish
i_comma:
    mv   a0, s7
    mv   a1, s10
    li   a2, 44
    call expect_char
    bltz a1, bad_sep
    mv   s7, a0
    lw   t3, 20(sp)
    li   t4, 2
    beq  t3, t4, i_mem
    li   t4, 3
    bne  t3, t4, i_rri
    mv   a0, s7
    mv   a1, s10
    call skip_ws
    bgeu a0, s10, bad_reg
    lbu  t0, 0(a0)
    li   t1, 40
    beq  t0, t1, i_mem
    li   t1, 45
    beq  t0, t1, i_mem
    li   t1, 43
    beq  t0, t1, i_mem
    addi t1, t0, -48
    li   t2, 10
    bltu t1, t2, i_mem

i_rri:
    mv   a0, s7
    mv   a1, s10
    call parse_reg
    bltz a1, bad_reg
    slli t0, a1, 15
    or   s8, s8, t0
    mv   s7, a0
    lw   t3, 20(sp)
    li   t4, 3
    bne  t3, t4, i_rri_imm
    mv   a0, s7
    mv   a1, s10
    call skip_ws
    bgeu a0, s10, i_finish
i_rri_imm:
    mv   a0, s7
    mv   a1, s10
    li   a2, 44
    call expect_char
    bltz a1, bad_sep
    mv   s7, a0
    mv   a1, s10
    mv   a0, s7
    call parse_imm
    mv   s7, a0
    li   t0, 1
    beq  a2, t0, bad_imm
    li   t0, 2
    beq  a2, t0, bad_range
    mv   s9, a1
    lw   t3, 20(sp)
    li   t4, 1
    bne  t3, t4, i_chk12
    li   t0, 32
    bgeu s9, t0, bad_shamt
    j    i_put
i_chk12:
    addi t0, s9, 1024
    addi t0, t0, 1024
    li   t1, 4096
    bgeu t0, t1, bad_range
i_put:
    slli t0, s9, 20
    or   s8, s8, t0
    j    i_finish

i_mem:
    mv   a0, s7
    mv   a1, s10
    call parse_mem
    mv   s7, a0
    bnez a3, i_mem_err
    slli t0, a2, 15
    or   s8, s8, t0
    slli t0, a1, 20
    or   s8, s8, t0
    j    i_finish
i_mem_err:
    li   t0, 1
    beq  a3, t0, bad_imm
    li   t0, 2
    beq  a3, t0, bad_range
    li   t0, 3
    beq  a3, t0, bad_mem
    j    bad_reg

i_finish:
    mv   a0, s7
    mv   a1, s10
    call skip_ws
    bne  a0, s10, bad_extra

    li   t0, 16384
    bgeu s5, t0, bad_depth
    lw   t0, 0(sp)
    lw   t1, 4(sp)
    sub  t0, t0, t1
    addi t0, t0, 64
    sub  t1, s6, s1
    bltu t1, t0, bad_full
    mv   a0, s1
    mv   a1, s5
    call put_hex8
    la   a1, sep1
    call put_str
    mv   a1, s8
    call put_hex8
    la   a1, sep2
    call put_str
    mv   a1, s2
    call put_dec
    la   a1, sep3
    call put_str
    lw   a1, 4(sp)
    lw   a2, 0(sp)
    call put_range
    la   a1, sep4
    call put_str
    mv   s1, a0
    addi s5, s5, 1
    j    pl_ret

bad_label:  la a0, e_label
            j  pl_error
bad_inst:   la a0, e_inst
            j  pl_error
bad_reg:    la a0, e_reg
            j  pl_error
bad_sep:    la a0, e_sep
            j  pl_error
bad_extra:  la a0, e_extra
            j  pl_error
bad_imm:    la a0, e_imm
            j  pl_error
bad_range:  la a0, e_range
            j  pl_error
bad_mem:    la a0, e_mem
            j  pl_error
bad_drange: la a0, e_drange
            j  pl_error
bad_dfull:  la a0, e_dfull
            j  pl_error
bad_dstr:   la a0, e_dstr
            j  pl_error
bad_dtext:  la a0, e_dtext
            j  pl_error
bad_dline:  la a0, e_dline
            j  pl_error
bad_depth:  la a0, e_depth
            j  pl_error
bad_full:   la a0, e_full
pl_error:
    call report_error
pl_ret:
    lw   ra, 44(sp)
    lw   s7, 40(sp)
    lw   s8, 36(sp)
    lw   s9, 32(sp)
    lw   s10, 28(sp)
    addi sp, sp, 48
    ret

bad_shamt:  la a0, e_shamt
            j  pl_error

report_error:
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

parse_imm:
parse_imm_ws:
    bgeu a0, a1, parse_imm_bad
    lbu  t0, 0(a0)
    li   t1, 32
    beq  t0, t1, parse_imm_ws_next
    li   t1, 9
    beq  t0, t1, parse_imm_ws_next
    li   t1, 13
    bne  t0, t1, parse_imm_sign
parse_imm_ws_next:
    addi a0, a0, 1
    j    parse_imm_ws
parse_imm_sign:
    li   t6, 0
    li   t1, 45
    bne  t0, t1, parse_imm_plus
    li   t6, 1
    addi a0, a0, 1
    j    parse_imm_start
parse_imm_plus:
    li   t1, 43
    bne  t0, t1, parse_imm_start
    addi a0, a0, 1
parse_imm_start:
    bgeu a0, a1, parse_imm_bad
    lbu  t0, 0(a0)
    li   t1, 48
    bne  t0, t1, parse_imm_dec
    addi t2, a0, 1
    bgeu t2, a1, parse_imm_dec
    lbu  t3, 0(t2)
    ori  t3, t3, 32
    li   t4, 120
    bne  t3, t4, parse_imm_dec
    addi a0, a0, 2
    li   t2, 0
    li   t5, 0
parse_imm_hex:
    bgeu a0, a1, parse_imm_hex_end
    lbu  t0, 0(a0)
    addi t3, t0, -48
    li   t4, 10
    bltu t3, t4, parse_imm_hex_dig
    ori  t3, t0, 32
    addi t3, t3, -97
    li   t4, 6
    bgeu t3, t4, parse_imm_hex_end
    addi t3, t3, 10
parse_imm_hex_dig:
    slli t2, t2, 4
    or   t2, t2, t3
    addi t5, t5, 1
    addi a0, a0, 1
    j    parse_imm_hex
parse_imm_hex_end:
    beqz t5, parse_imm_bad
    li   t4, 8
    bltu t4, t5, parse_imm_range
    j    parse_imm_neg
parse_imm_dec:
    li   t2, 0
    li   t5, 0
parse_imm_dec_loop:
    bgeu a0, a1, parse_imm_dec_end
    lbu  t0, 0(a0)
    addi t3, t0, -48
    li   t4, 10
    bgeu t3, t4, parse_imm_dec_end
    li   t4, 429496729
    bltu t4, t2, parse_imm_range
    bne  t2, t4, parse_imm_dec_ok
    li   t4, 5
    bltu t4, t3, parse_imm_range
parse_imm_dec_ok:
    li   t4, 10
    mul  t2, t2, t4
    add  t2, t2, t3
    addi t5, t5, 1
    addi a0, a0, 1
    j    parse_imm_dec_loop
parse_imm_dec_end:
    beqz t5, parse_imm_bad
    bnez t6, parse_imm_dec_negchk
    bltz t2, parse_imm_range
    j    parse_imm_neg
parse_imm_dec_negchk:
    li   t4, 0x80000000
    bltu t4, t2, parse_imm_range
parse_imm_neg:
    beqz t6, parse_imm_ok
    neg  t2, t2
parse_imm_ok:
    mv   a1, t2
    li   a2, 0
    ret
parse_imm_range:
    li   a1, 0
    li   a2, 2
    ret
parse_imm_bad:
    li   a1, 0
    li   a2, 1
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
    call skip_ws
    bgeu a0, a1, parse_mem_bad_imm
    lbu  t0, 0(a0)
    li   t1, 40
    beq  t0, t1, parse_mem_noimm
    lw   a1, 4(sp)
    call parse_imm
    bnez a2, parse_mem_immerr
    addi t0, a1, 1024
    addi t0, t0, 1024
    li   t1, 4096
    bgeu t0, t1, parse_mem_range
    sw   a1, 8(sp)
    j    parse_mem_paren
parse_mem_noimm:
    sw   zero, 8(sp)
parse_mem_paren:
    lw   a1, 4(sp)
    li   a2, 40
    call expect_char
    bltz a1, parse_mem_bad_paren
    lw   a1, 4(sp)
    call parse_reg
    bltz a1, parse_mem_bad_reg
    sw   a1, 0(sp)
    lw   a1, 4(sp)
    li   a2, 41
    call expect_char
    bltz a1, parse_mem_bad_paren
    lw   a1, 8(sp)
    lw   a2, 0(sp)
    li   a3, 0
    j    parse_mem_ret
parse_mem_immerr:
    mv   a3, a2
    j    parse_mem_fail
parse_mem_bad_imm:
    li   a3, 1
    j    parse_mem_fail
parse_mem_range:
    li   a3, 2
    j    parse_mem_fail
parse_mem_bad_paren:
    li   a3, 3
    j    parse_mem_fail
parse_mem_bad_reg:
    li   a3, 4
parse_mem_fail:
    li   a1, 0
    li   a2, 0
parse_mem_ret:
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret

write_file:
    mv   s9, a2
    mv   s7, a1
    li   a1, 1
    li   a7, 1024
    ecall
    bltz a0, err_create
    mv   s10, a0
    mv   a1, s7
    mv   a2, s9
    li   a7, 64
    ecall
    bne  a0, s9, err_write
    mv   a0, s10
    li   a7, 57
    ecall
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
