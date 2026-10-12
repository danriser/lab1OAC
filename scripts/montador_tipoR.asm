# =====================================================================
#  montador_tipo_r.asm  -  Montador RISC-V (RV32I) para instruções do tipo R
#  (add, sub, sll, slt, sltu, xor, srl, sra, or, and)  -  roda no RARS 1.6
#
#  ENTRADA : arquivo .asm  (nome digitado no console OU argumento do programa)
#  SAÍDA   : <nome>_text.mif  no formato do Guia / arquivo de referência:
#            quebras CRLF, ";   % linha: <linha original com comentário> %"
#
#  Formato do tipo R (módulo 2 do guia):
#     31      25 24   20 19   15 14  12 11    7 6     0
#    | funct7  |  rs2  |  rs1  |funct3|  rd   | opcode |      opcode = 0x33
#
#  Palavra = (funct7<<25) | (rs2<<20) | (rs1<<15) | (funct3<<12) | (rd<<7) | 0x33
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
e_inst:      .asciz "instrucao desconhecida ou nao suportada (aceito: add sub sll slt sltu xor srl sra or and)"
e_reg:       .asciz "registrador invalido"
e_sep:       .asciz "esperada virgula entre os operandos"
e_extra:     .asciz "texto sobrando depois do ultimo operando"
e_dir:       .asciz "diretiva nao suportada"
e_label:     .asciz "rotulo vazio antes de ':'"
e_full:      .asciz "memoria de saida esgotada"
e_depth:     .asciz "programa maior que 16384 instrucoes (DEPTH do MIF)"
hdr:         .asciz "DEPTH = 16384;\r\nWIDTH = 32;\r\nADDRESS_RADIX = HEX;\r\nDATA_RADIX = HEX;\r\nCONTENT\r\nBEGIN\r\n"
ftr:         .asciz "END;\r\n"
suffix:      .asciz "_text.mif"
sep1:        .asciz " : "
sep2:        .asciz ";   % "
sep3:        .asciz ": "
sep4:        .asciz " %\r\n"

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
f3tab:   .byte 0, 0, 1, 2, 3, 4, 5, 5, 6, 7
f7tab:   .byte 0, 32, 0, 0, 0, 0, 0, 32, 0, 0
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
#  Locais: s7 cursor, s8 palavra, s9 início do texto, s10 fim do texto,
#          0(sp) fim da linha original, 4(sp) início da linha original
# =====================================================================
process_line:
    addi sp, sp, -32
    sw   ra, 28(sp)
    sw   s7, 24(sp)
    sw   s8, 20(sp)
    sw   s9, 16(sp)
    sw   s10, 12(sp)
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
    li   a3, 10
    call lookup
    bltz a0, bad_inst
    lw   s7, 8(sp)                 # cursor depois do mnemônico
    la   t0, f3tab
    add  t0, t0, a0
    lbu  t1, 0(t0)                 # funct3
    la   t0, f7tab
    add  t0, t0, a0
    lbu  t2, 0(t0)                 # funct7
    slli t1, t1, 12
    slli t2, t2, 25
    or   s8, t1, t2
    ori  s8, s8, 0x33              # opcode do tipo R

    # ----- rd -----
    mv   a0, s7
    mv   a1, s10
    call parse_reg
    bltz a1, bad_reg
    slli t0, a1, 7
    or   s8, s8, t0
    mv   s7, a0
    # ----- vÃ­rgula -----
    mv   a0, s7
    mv   a1, s10
    call skip_ws
    bgeu a0, s10, bad_sep
    lbu  t0, 0(a0)
    li   t1, 44
    bne  t0, t1, bad_sep
    addi s7, a0, 1
    # ----- rs1 -----
    mv   a0, s7
    mv   a1, s10
    call parse_reg
    bltz a1, bad_reg
    slli t0, a1, 15
    or   s8, s8, t0
    mv   s7, a0
    # ----- vÃ­rgula -----
    mv   a0, s7
    mv   a1, s10
    call skip_ws
    bgeu a0, s10, bad_sep
    lbu  t0, 0(a0)
    li   t1, 44
    bne  t0, t1, bad_sep
    addi s7, a0, 1
    # ----- rs2 -----
    mv   a0, s7
    mv   a1, s10
    call parse_reg
    bltz a1, bad_reg
    slli t0, a1, 20
    or   s8, s8, t0
    mv   s7, a0
    # ----- nÃ£o pode sobrar nada -----
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
bad_depth:  la a0, e_depth
            j  pl_error
bad_full:   la a0, e_full
pl_error:
    call report_error
pl_ret:
    lw   ra, 28(sp)
    lw   s7, 24(sp)
    lw   s8, 20(sp)
    lw   s9, 16(sp)
    lw   s10, 12(sp)
    addi sp, sp, 32
    ret

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
