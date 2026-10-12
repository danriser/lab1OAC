# =====================================================================
#  montador_tipo_i.asm  -  Montador RISC-V (RV32I) para instruções do tipo I
#  addi slti sltiu xori ori andi slli srli srai   (aritméticas com imediato)
#  lb lh lw lbu lhu                               (loads)
#  jalr                                           -  roda no RARS 1.6
#
#  ENTRADA : arquivo .asm  (nome digitado no console OU argumento do programa)
#  SAÍDA   : <nome>_text.mif  (mesmo formato do montador_tipoR.asm)
#
#  Formato do tipo I (módulo 2 do guia):
#     31          20 19   15 14  12 11    7 6     0
#    | imm[11:0]   |  rs1  |funct3|  rd   | opcode |
#
#  opcode: 0x13 (aritméticas)  0x03 (loads)  0x67 (jalr)
#  Nos deslocamentos (slli/srli/srai) o imediato é  funct7(7 bits) | shamt(5 bits);
#  só srai tem funct7 = 0100000.
#
#  Sintaxes aceitas:
#     addi rd, rs1, imm        slli rd, rs1, shamt (0..31)
#     lw   rd, imm(rs1)        lw   rd, (rs1)            (imediato omitido = 0)
#     jalr rd, rs1, imm        jalr rd, imm(rs1)         jalr rd, rs1       jalr rs1
#  Imediato: decimal (+/-), ou hexadecimal 0xHHHHHHHH (32 bits); precisa caber em -2048..2047.
#  Registradores: x0..x31 e nomes ABI (zero ra sp gp tp t0-t6 s0/fp s1-s11 a0-a7).
#
#  Registradores GLOBAIS do montador (só a main e process_line os usam):
#     s0  ponteiro do início da linha atual     s1  ponteiro de escrita em outbuf
#     s2  número da linha atual (começa em 1)   s3  seção: 0 = .text, 1 = .data
#     s4  quantidade de erros                   s5  índice da próxima instrução
#     s6  fim (limite) de outbuf                s7  descritor do arquivo (na main)
#     s8  início de outbuf (na main)            s11 fim da linha atual
#  Serviços do RARS usados: 4, 1, 8, 9, 1024, 63, 64, 57, 93 (módulo 8).
# =====================================================================

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
msg_ok:      .asciz "Montagem concluida. Arquivo gerado: "
msg_count:   .asciz "\nInstrucoes traduzidas: "
e_inst:      .asciz "instrucao desconhecida ou nao suportada (aceito: addi slti sltiu xori ori andi slli srli srai lb lh lw lbu lhu jalr)"
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
hdr:         .asciz "DEPTH = 16384;\r\nWIDTH = 32;\r\nADDRESS_RADIX = HEX;\r\nDATA_RADIX = HEX;\r\nCONTENT\r\nBEGIN\r\n"
ftr:         .asciz "END;\r\n"
suffix:      .asciz "_text.mif"
sep1:        .asciz " : "
sep2:        .asciz ";   % "
sep3:        .asciz ": "
sep4:        .asciz " %\r\n"

.align 3
instnames:
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
f3tab:   .byte 0, 2, 3, 4, 6, 7, 1, 5, 5, 0, 1, 2, 4, 5, 0
f7tab:   .byte 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0, 0, 0, 0, 0
optab:   .byte 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x13, 0x03, 0x03, 0x03, 0x03, 0x03, 0x67
kindtab: .byte 0, 0, 0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 2, 2, 3     # 0 rd,rs1,imm | 1 rd,rs1,shamt | 2 rd,imm(rs1) | 3 jalr
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

.align 2
fname:   .space 260
outname: .space 330
inbuf:   .space 70000

# =====================================================================
.text
.globl main
main:
    # ---------- 1. nome do arquivo: argumento do programa ou console ----------
    blez a0, ask_name              # a0 = quantidade de argumentos
    lw   t2, 0(a1)                 # a1 = lista de nomes; pega o primeiro
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
    la   t0, fname                 # remove o \n (ou \r) do final (mÃ³dulo 11)
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

    # ---------- 2. lê o arquivo inteiro para inbuf (módulo 8) ----------
have_name:
    la   a0, fname
    li   a1, 0                     # 0 = somente leitura
    li   a7, 1024
    ecall
    bltz a0, err_open
    mv   s0, a0                    # descritor
    la   s1, inbuf
    li   s2, 0                     # total de bytes
read_loop:
    li   t0, 65000
    bge  s2, t0, err_big
    mv   a0, s0
    mv   a1, s1
    li   a2, 4096
    li   a7, 63
    ecall
    blez a0, read_done             # 0 = fim do arquivo
    add  s1, s1, a0
    add  s2, s2, a0
    j    read_loop
read_done:
    mv   a0, s0
    li   a7, 57
    ecall
    la   t0, inbuf
    add  t0, t0, s2
    sb   zero, 0(t0)               # marca o fim do texto

    # ---------- 3. nome de saída: tira a extensão e põe _text.mif ----------
    la   t0, fname
    la   t1, outname
    li   t2, 0                     # posição do último '.' (0 = nenhum)
name_copy:
    lbu  t3, 0(t0)
    beqz t3, name_end
    sb   t3, 0(t1)
    li   t4, 46                    # '.'
    bne  t3, t4, name_chk_sep
    mv   t2, t1
    j    name_adv
name_chk_sep:
    li   t4, 47                    # '/'
    beq  t3, t4, name_reset
    li   t4, 92                    # '\'
    bne  t3, t4, name_adv
name_reset:
    li   t2, 0                     # ponto antes de uma pasta não é extensão
name_adv:
    addi t0, t0, 1
    addi t1, t1, 1
    j    name_copy
name_end:
    beqz t2, name_suffix
    mv   t1, t2                    # sobrescreve a partir do último ponto
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

    # ---------- 4. reserva a área de saída (sbrk) e escreve o cabeçalho ----------
    li   a0, 524288
    li   a7, 9
    ecall
    mv   s8, a0                    # início de outbuf
    mv   s1, a0                    # ponteiro de escrita
    li   t0, 524288
    add  s6, a0, t0                # limite
    mv   a0, s1
    la   a1, hdr
    call put_str
    mv   s1, a0

    # ---------- 5. traduz linha a linha ----------
    li   s2, 0                     # nº da linha
    li   s3, 0                     # seção .text
    li   s4, 0                     # erros
    li   s5, 0                     # índice da instrução
    la   s0, inbuf
line_loop:
    lbu  t0, 0(s0)
    beqz t0, lines_done
    addi s2, s2, 1
    mv   a0, s0
    call find_eol
    mv   s11, a0                   # fim da linha ('\n' ou terminador)
    mv   a0, s0
    mv   a1, s11
    call process_line
    mv   s0, s11
    lbu  t0, 0(s0)
    beqz t0, lines_done
    addi s0, s0, 1                 # pula o '\n'
    j    line_loop

    # ---------- 6. grava o arquivo (só se não houve erro) ----------
lines_done:
    bnez s4, finish_errors
    mv   a0, s1
    la   a1, ftr
    call put_str
    mv   s1, a0
    la   a0, outname
    li   a1, 1                     # 1 = gravar
    li   a7, 1024
    ecall
    bltz a0, err_create
    mv   s7, a0
    mv   a0, s7
    mv   a1, s8
    sub  a2, s1, s8
    mv   s9, a2                    # bytes a gravar
    li   a7, 64
    ecall
    bne  a0, s9, err_write
    mv   a0, s7
    li   a7, 57
    ecall
    la   a0, msg_ok
    li   a7, 4
    ecall
    la   a0, outname
    li   a7, 4
    ecall
    la   a0, msg_count
    li   a7, 4
    ecall
    mv   a0, s5
    li   a7, 1
    ecall
    la   a0, msg_nl
    li   a7, 4
    ecall
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
fatal:                              # a0 = mensagem; imprime e termina
    li   a7, 4
    ecall
    li   a0, 1
    li   a7, 93
    ecall

# =====================================================================
#  process_line(a0 = início, a1 = fim)  -  trata UMA linha do .asm
#  Estrutura: tira comentário -> tira espaços -> rótulo -> diretiva ->
#             instrução -> grava a linha no MIF.
#  Locais: s7 cursor, s8 palavra, s9 início do texto / imediato, s10 fim do texto,
#          0(sp) fim da linha original, 4(sp) início da linha original,
#          8(sp) fim do mnemônico, 20(sp) tipo de operandos, 24(sp) índice da instrução
# =====================================================================
process_line:
    addi sp, sp, -48
    sw   ra, 44(sp)
    sw   s7, 40(sp)
    sw   s8, 36(sp)
    sw   s9, 32(sp)
    sw   s10, 28(sp)
    sw   a0, 4(sp)                 # início original da linha (com recuo)
    call trim_end                  # a1 = fim sem espaços/\r finais
    sw   a1, 0(sp)                 # fim original (o comentário '#' fica incluído)
    mv   t0, a0                    # procura '#' (comentário)
cmt_loop:
    bgeu t0, a1, cmt_done
    lbu  t1, 0(t0)
    li   t2, 35
    beq  t1, t2, cmt_cut
    addi t0, t0, 1
    j    cmt_loop
cmt_cut:
    mv   a1, t0                    # a linha termina no '#'
cmt_done:
    call skip_ws                   # a0 = 1º caractere útil
    mv   s9, a0
    call trim_end                  # a1 = fim sem espaços finais
    mv   s10, a1
    bgeu s9, s10, pl_ret           # linha vazia
    mv   s7, s9

    # ----- rótulo? (identificador seguido de ':') -----
    mv   a0, s7
    mv   a1, s10
    call scan_ident
    bgeu a0, s10, no_label
    lbu  t0, 0(a0)
    li   t1, 58                    # ':'
    bne  t0, t1, no_label
    beq  a0, s7, bad_label
    addi s7, a0, 1
    mv   a0, s7
    mv   a1, s10
    call skip_ws
    mv   s7, a0
    bgeu s7, s10, pl_ret           # linha só com rótulo
no_label:

    # ----- diretiva? -----
    lbu  t0, 0(s7)
    li   t1, 46                    # '.'
    bne  t0, t1, not_dir
    mv   a0, s7
    mv   a1, s10
    call scan_ident
    sub  a1, a0, s7
    mv   a0, s7
    la   a2, dirnames
    li   a3, 4
    call lookup
    beqz a0, dir_text
    li   t0, 1
    beq  a0, t0, dir_data
    bgtz a0, pl_ret                # .globl / .global: ignora
    bnez s3, pl_ret                # desconhecida dentro de .data: ignora
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
    bnez s3, pl_ret                # dentro de .data: nada a traduzir aqui


    # ----- mnemônico -----
    mv   a0, s7
    mv   a1, s10
    call scan_ident
    sw   a0, 8(sp)                 # fim do mnemônico
    sub  a1, a0, s7
    beqz a1, bad_inst
    mv   a0, s7
    la   a2, instnames
    li   a3, 15
    call lookup
    bltz a0, bad_inst
    lw   s7, 8(sp)                 # cursor depois do mnemônico
    sw   a0, 24(sp)                # índice da instrução
    la   t0, kindtab
    add  t0, t0, a0
    lbu  t3, 0(t0)
    sw   t3, 20(sp)                # tipo de operandos
    la   t0, optab
    add  t0, t0, a0
    lbu  t4, 0(t0)                 # opcode
    la   t0, f3tab
    add  t0, t0, a0
    lbu  t1, 0(t0)                 # funct3
    la   t0, f7tab
    add  t0, t0, a0
    lbu  t2, 0(t0)                 # funct7 (só srai)
    slli t1, t1, 12
    slli t2, t2, 25
    or   s8, t1, t2
    or   s8, s8, t4

    # ----- rd -----
    mv   a0, s7
    mv   a1, s10
    call parse_reg
    bltz a1, bad_reg
    slli t0, a1, 7
    or   s8, s8, t0
    mv   s7, a0
    # ----- jalr com um operando só:  jalr rs1  ==  jalr ra, rs1, 0 -----
    lw   t3, 20(sp)
    li   t4, 3
    bne  t3, t4, i_comma
    mv   a0, s7
    mv   a1, s10
    call skip_ws
    bltu a0, s10, i_comma
    srli t0, s8, 7
    andi t0, t0, 31                # o "rd" lido era, na verdade, rs1
    li   t1, 0xFFFFF07F
    and  s8, s8, t1                # zera rd
    ori  s8, s8, 128               # rd = ra (x1)
    slli t0, t0, 15
    or   s8, s8, t0
    j    i_finish
    # ----- vírgula depois de rd -----
i_comma:
    mv   a0, s7
    mv   a1, s10
    li   a2, 44
    call expect_char
    bltz a1, bad_sep
    mv   s7, a0
    lw   t3, 20(sp)
    li   t4, 2
    beq  t3, t4, i_mem             # loads: rd, imm(rs1)
    li   t4, 3
    bne  t3, t4, i_rri
    # jalr: "imm(rs1)" (começa com dígito, sinal ou '(') ou "rs1[, imm]"
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

    # ----- rs1 [, imm] -----
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
    mv   a0, s7                    # jalr rd, rs1  (imediato omitido = 0)
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
    mv   s9, a1                    # valor do imediato
    lw   t3, 20(sp)
    li   t4, 1
    bne  t3, t4, i_chk12
    li   t0, 32                    # shamt: 0..31
    bgeu s9, t0, bad_shamt
    j    i_put
i_chk12:
    addi t0, s9, 1024              # -2048..2047  (2048 não cabe no addi)
    addi t0, t0, 1024
    li   t1, 4096
    bgeu t0, t1, bad_range
i_put:
    slli t0, s9, 20                # imm[11:0] -> bits 31:20 (os bits de sinal sobram e somem)
    or   s8, s8, t0
    j    i_finish

    # ----- imm(rs1) -----
i_mem:
    mv   a0, s7
    mv   a1, s10
    call parse_mem
    mv   s7, a0
    bnez a3, i_mem_err
    slli t0, a2, 15                # rs1
    or   s8, s8, t0
    slli t0, a1, 20                # imm[11:0]
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

    # ----- não pode sobrar nada -----
i_finish:
    mv   a0, s7
    mv   a1, s10
    call skip_ws
    bne  a0, s10, bad_extra

    # ----- grava:  IIIIIIII : PPPPPPPP;   % linha: texto original %\r\n  -----
    li   t0, 16384
    bgeu s5, t0, bad_depth
    lw   t0, 0(sp)
    lw   t1, 4(sp)
    sub  t0, t0, t1                # tamanho da linha original
    addi t0, t0, 64
    sub  t1, s6, s1
    bltu t1, t0, bad_full
    mv   a0, s1
    mv   a1, s5
    call put_hex8                  # Índice da palavra
    la   a1, sep1
    call put_str
    mv   a1, s8
    call put_hex8                  # palavra de 32 bits
    la   a1, sep2
    call put_str
    mv   a1, s2
    call put_dec                   # nº da linha no .asm
    la   a1, sep3
    call put_str
    lw   a1, 4(sp)
    lw   a2, 0(sp)
    call put_range                 # linha ORIGINAL, literal (recuo, rótulo e comentário)
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

# =====================================================================
#  Sub-rotinas folha (usam só a e t)
# =====================================================================

# report_error(a0 = mensagem): imprime "Erro na linha N: mensagem" e conta o erro
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

# find_eol(a0 = ptr) -> a0 = posição do '\n' ou do terminador 0
find_eol:
    lbu  t0, 0(a0)
    beqz t0, find_eol_ret
    li   t1, 10
    beq  t0, t1, find_eol_ret
    addi a0, a0, 1
    j    find_eol
find_eol_ret:
    ret

# skip_ws(a0 = cursor, a1 = fim) -> a0 = primeiro caractere que não é espaço/tab/\r
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

# trim_end(a0 = início, a1 = fim) -> a1 = fim sem espaços finais
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

# scan_ident(a0 = cursor, a1 = fim) -> a0 = fim da sequência [A-Za-z0-9_.$]
scan_ident:
    bgeu a0, a1, scan_ident_ret
    lbu  t0, 0(a0)
    li   t1, 95                    # '_'
    beq  t0, t1, scan_ident_next
    li   t1, 46                    # '.'
    beq  t0, t1, scan_ident_next
    li   t1, 36                    # '$'
    beq  t0, t1, scan_ident_next
    addi t2, t0, -48               # dígito?
    li   t1, 10
    bltu t2, t1, scan_ident_next
    ori  t2, t0, 32                # letra (maiúscula ou minúscula)?
    addi t2, t2, -97
    li   t1, 26
    bltu t2, t1, scan_ident_next
scan_ident_ret:
    ret
scan_ident_next:
    addi a0, a0, 1
    j    scan_ident

# lookup(a0 = texto, a1 = tamanho, a2 = tabela, a3 = qtd) -> a0 = Índice ou -1
# A tabela guarda nomes terminados em 0, cada um em 8 bytes.
lookup:
    li   t0, 0                     # i
lookup_entry:
    bgeu t0, a3, lookup_none
    slli t1, t0, 3
    add  t1, t1, a2                # endereço da entrada i
    li   t2, 0                     # posição dentro do nome
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
    add  t4, t1, a1                # o nome da tabela també também tem que acabar aqui
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

# parse_xnum(a0 = texto, a1 = tamanho) -> a0 = número (0..31) de "x0".."x31", ou -1
parse_xnum:
    li   t0, 2
    blt  a1, t0, xnum_no
    li   t0, 3
    blt  t0, a1, xnum_no
    lbu  t0, 0(a0)
    li   t1, 120                   # 'x'
    bne  t0, t1, xnum_no
    li   t2, 0                     # valor
    li   t3, 1                     # posição
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

# parse_reg(a0 = cursor, a1 = fim) -> a0 = novo cursor, a1 = número do registrador ou -1
parse_reg:
    addi sp, sp, -16
    sw   ra, 12(sp)
    call skip_ws
    sw   a0, 4(sp)                 # início do nome
    call scan_ident
    sw   a0, 8(sp)                 # fim do nome
    lw   t0, 4(sp)
    sub  a1, a0, t0
    mv   a0, t0
    call parse_xnum                # tenta x0..x31
    bgez a0, parse_reg_ok
    lw   a0, 4(sp)                 # tenta nomes ABI (zero, ra, t0, a0, ...)
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

# put_str(a0 = destino, a1 = texto terminado em 0) -> a0 = novo destino
put_str:
    lbu  t0, 0(a1)
    beqz t0, put_str_ret
    sb   t0, 0(a0)
    addi a0, a0, 1
    addi a1, a1, 1
    j    put_str
put_str_ret:
    ret

# put_range(a0 = destino, a1 = início, a2 = fim) -> a0 = novo destino
put_range:
    bgeu a1, a2, put_range_ret
    lbu  t0, 0(a1)
    sb   t0, 0(a0)
    addi a0, a0, 1
    addi a1, a1, 1
    j    put_range
put_range_ret:
    ret

# put_hex8(a0 = destino, a1 = valor) -> a0 = novo destino (8 dígitos hexa minúsculos)
put_hex8:
    li   t0, 28
put_hex8_loop:
    srl  t1, a1, t0
    andi t1, t1, 15
    li   t2, 10
    blt  t1, t2, put_hex8_digit
    addi t1, t1, 87                # 'a' - 10
    j    put_hex8_store
put_hex8_digit:
    addi t1, t1, 48                # '0'
put_hex8_store:
    sb   t1, 0(a0)
    addi a0, a0, 1
    addi t0, t0, -4
    bgez t0, put_hex8_loop
    ret

# put_dec(a0 = destino, a1 = valor >= 0) -> a0 = novo destino (decimal)
put_dec:
    li   t0, 10
    li   t2, 1                     # maior potência de 10 que cabe no valor
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

# parse_imm(a0 = cursor, a1 = fim) -> a0 = novo cursor, a1 = valor (32 bits),
#                                     a2 = 0 ok | 1 inválido/ausente | 2 não cabe em 32 bits
# Aceita sinal opcional (+/-), decimal (até 2^31-1, ou -2^31) e hexa 0xHHHHHHHH (até 8 dígitos).
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
    li   t6, 0                     # t6 = 1 se negativo
    li   t1, 45                    # '-'
    bne  t0, t1, parse_imm_plus
    li   t6, 1
    addi a0, a0, 1
    j    parse_imm_start
parse_imm_plus:
    li   t1, 43                    # '+'
    bne  t0, t1, parse_imm_start
    addi a0, a0, 1
parse_imm_start:
    bgeu a0, a1, parse_imm_bad
    lbu  t0, 0(a0)
    li   t1, 48                    # '0'
    bne  t0, t1, parse_imm_dec
    addi t2, a0, 1
    bgeu t2, a1, parse_imm_dec
    lbu  t3, 0(t2)
    ori  t3, t3, 32
    li   t4, 120                   # 'x'
    bne  t3, t4, parse_imm_dec
    addi a0, a0, 2                 # pula o "0x"
    li   t2, 0                     # valor
    li   t5, 0                     # quantidade de dígitos
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
    bltu t4, t5, parse_imm_range   # mais de 8 dígitos
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
    li   t4, 429496729             # (2^32 - 1) / 10: evita estouro de 32 bits
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
    bltz t2, parse_imm_range       # decimal positivo precisa ser <= 2^31 - 1
    j    parse_imm_neg
parse_imm_dec_negchk:
    li   t4, 0x80000000
    bltu t4, t2, parse_imm_range   # decimal negativo precisa ser >= -2^31
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

# expect_char(a0 = cursor, a1 = fim, a2 = caractere) -> a0 = cursor depois do caractere,
#                                                      a1 = 0 se achou, -1 se não
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

# parse_mem(a0 = cursor, a1 = fim) -> a0 = novo cursor, a1 = imediato (12 bits, com sinal),
#                                     a2 = registrador base, a3 = status
# Lê  imm(reg)  ou  (reg)  (imediato omitido = 0).
# status: 0 ok | 1 imediato inválido | 2 imediato fora de -2048..2047 | 3 faltou '(' ou ')' | 4 registrador inválido
parse_mem:
    addi sp, sp, -16
    sw   ra, 12(sp)
    sw   a1, 4(sp)                 # fim da linha
    call skip_ws
    bgeu a0, a1, parse_mem_bad_imm
    lbu  t0, 0(a0)
    li   t1, 40                    # '('
    beq  t0, t1, parse_mem_noimm
    lw   a1, 4(sp)
    call parse_imm
    bnez a2, parse_mem_immerr
    addi t0, a1, 1024              # -2048..2047  (2048 não cabe no addi)
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
    sw   a1, 0(sp)                 # registrador base
    lw   a1, 4(sp)
    li   a2, 41                    # ')'
    call expect_char
    bltz a1, parse_mem_bad_paren
    lw   a1, 8(sp)
    lw   a2, 0(sp)
    li   a3, 0
    j    parse_mem_ret
parse_mem_immerr:
    mv   a3, a2                    # 1 = inválido, 2 = fora de 32 bits
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
