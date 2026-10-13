# Peca 5 - montar a palavra de 32 bits
# Esta peca mostra como o process_line encaixa os campos de cada formato (mesmas contas do main.asm).
# Cada campo e deslocado com slli para a posicao certa e juntado com or. Nos formatos S, B e J o imediato
# e partido em pedacos (por isso os srli/andi/slli). As palavras esperadas foram geradas pelo proprio RARS.
#   R: funct7(31:25) rs2(24:20) rs1(19:15) funct3(14:12) rd(11:7) opcode(6:0)
#   I: imm[11:0](31:20) rs1 funct3 rd opcode
#   S: imm[11:5](31:25) rs2 rs1 funct3 imm[4:0](11:7) opcode
#   B: imm[12](31) imm[10:5](30:25) rs2 rs1 funct3 imm[4:1](11:8) imm[11](7) opcode
#   U: imm[31:12](31:12) rd opcode
#   J: imm[20](31) imm[10:1](30:21) imm[11](20) imm[19:12](19:12) rd opcode

.data
t_obtido:   .asciz "  obtido="
t_esperado: .asciz "  esperado="
t_seta:     .asciz "  -> "
t_ok:       .asciz "OK"
t_erro:     .asciz "ERRO"
t_nl:       .asciz "\n"
d0: .asciz "R  add t0, t1, t2"
d1: .asciz "R  sub t3, t1, t3"
d2: .asciz "I  addi t2, zero, 4"
d3: .asciz "I  slti t1, t2, -1"
d4: .asciz "I  lw t2, 0(t1)"
d5: .asciz "S  sw t2, 32(t1)"
d6: .asciz "S  sw t0, -4(s0)"
d7: .asciz "U  lui t1, 0x1001"
d8: .asciz "U  auipc t0, 4"
d9: .asciz "B  beq t1, t2, +8"
d10: .asciz "B  bne t0, zero, -4"
d11: .asciz "J  jal ra, +8"
d12: .asciz "J  jal zero, -8"

.text
main:
    # R: add t0, t1, t2   -> funct7=0 rs2=7 rs1=6 funct3=0 rd=5
    li   a0, 0
    li   a1, 7
    li   a2, 6
    li   a3, 0
    li   a4, 5
    call tipo_r
    li   a1, 0x007302b3
    la   a2, d0
    call confere_hex
    # R: sub t3, t1, t3   -> funct7=32 rs2=28 rs1=6 funct3=0 rd=28
    li   a0, 32
    li   a1, 28
    li   a2, 6
    li   a3, 0
    li   a4, 28
    call tipo_r
    li   a1, 0x41c30e33
    la   a2, d1
    call confere_hex
    # I: addi t2, zero, 4
    li   a0, 4
    li   a1, 0
    li   a2, 0
    li   a3, 7
    li   a4, 0x13
    call tipo_i
    li   a1, 0x00400393
    la   a2, d2
    call confere_hex
    # I: slti t1, t2, -1   (imediato negativo: os bits de sinal saem no slli)
    li   a0, -1
    li   a1, 7
    li   a2, 2
    li   a3, 6
    li   a4, 0x13
    call tipo_i
    li   a1, 0xfff3a313
    la   a2, d3
    call confere_hex
    # I: lw t2, 0(t1)
    li   a0, 0
    li   a1, 6
    li   a2, 2
    li   a3, 7
    li   a4, 0x03
    call tipo_i
    li   a1, 0x00032383
    la   a2, d4
    call confere_hex
    # S: sw t2, 32(t1)
    li   a0, 32
    li   a1, 7
    li   a2, 6
    li   a3, 2
    call tipo_s
    li   a1, 0x02732023
    la   a2, d5
    call confere_hex
    # S: sw t0, -4(s0)
    li   a0, -4
    li   a1, 5
    li   a2, 8
    li   a3, 2
    call tipo_s
    li   a1, 0xfe542e23
    la   a2, d6
    call confere_hex
    # U: lui t1, 0x1001
    li   a0, 0x1001
    li   a1, 6
    li   a2, 0x37
    call tipo_u
    li   a1, 0x01001337
    la   a2, d7
    call confere_hex
    # U: auipc t0, 4
    li   a0, 4
    li   a1, 5
    li   a2, 0x17
    call tipo_u
    li   a1, 0x00004297
    la   a2, d8
    call confere_hex
    # B: beq t1, t2, +8
    li   a0, 8
    li   a1, 7
    li   a2, 6
    li   a3, 0
    call tipo_b
    li   a1, 0x00730463
    la   a2, d9
    call confere_hex
    # B: bne t0, zero, -4
    li   a0, -4
    li   a1, 0
    li   a2, 5
    li   a3, 1
    call tipo_b
    li   a1, 0xfe029ee3
    la   a2, d10
    call confere_hex
    # J: jal ra, +8
    li   a0, 8
    li   a1, 1
    call tipo_j
    li   a1, 0x008000ef
    la   a2, d11
    call confere_hex
    # J: jal zero, -8
    li   a0, -8
    li   a1, 0
    call tipo_j
    li   a1, 0xff9ff06f
    la   a2, d12
    call confere_hex
    li   a7, 10
    ecall

# tipo_r(a0 = funct7, a1 = rs2, a2 = rs1, a3 = funct3, a4 = rd) -> a0 = palavra
tipo_r:
    slli a0, a0, 25
    slli a1, a1, 20
    slli a2, a2, 15
    slli a3, a3, 12
    slli a4, a4, 7
    or   a0, a0, a1
    or   a0, a0, a2
    or   a0, a0, a3
    or   a0, a0, a4
    ori  a0, a0, 0x33
    ret

# tipo_i(a0 = imediato, a1 = rs1, a2 = funct3, a3 = rd, a4 = opcode) -> a0 = palavra
tipo_i:
    slli a0, a0, 20
    slli a1, a1, 15
    slli a2, a2, 12
    slli a3, a3, 7
    or   a0, a0, a1
    or   a0, a0, a2
    or   a0, a0, a3
    or   a0, a0, a4
    ret

# tipo_s(a0 = imediato, a1 = rs2, a2 = rs1, a3 = funct3) -> a0 = palavra
tipo_s:
    andi t0, a0, 31
    slli t0, t0, 7
    srai t1, a0, 5
    slli t1, t1, 25
    slli a1, a1, 20
    slli a2, a2, 15
    slli a3, a3, 12
    or   t0, t0, t1
    or   t0, t0, a1
    or   t0, t0, a2
    or   t0, t0, a3
    ori  a0, t0, 0x23
    ret

# tipo_u(a0 = imediato de 20 bits, a1 = rd, a2 = opcode) -> a0 = palavra
tipo_u:
    slli a0, a0, 12
    slli a1, a1, 7
    or   a0, a0, a1
    or   a0, a0, a2
    ret

# tipo_b(a0 = deslocamento em bytes, a1 = rs2, a2 = rs1, a3 = funct3) -> a0 = palavra
tipo_b:
    srli t1, a0, 12
    andi t1, t1, 1
    slli t1, t1, 31
    srli t2, a0, 5
    andi t2, t2, 63
    slli t2, t2, 25
    or   t1, t1, t2
    srli t2, a0, 1
    andi t2, t2, 15
    slli t2, t2, 8
    or   t1, t1, t2
    srli t2, a0, 11
    andi t2, t2, 1
    slli t2, t2, 7
    or   t1, t1, t2
    slli a1, a1, 20
    slli a2, a2, 15
    slli a3, a3, 12
    or   t1, t1, a1
    or   t1, t1, a2
    or   t1, t1, a3
    ori  a0, t1, 0x63
    ret

# tipo_j(a0 = deslocamento em bytes, a1 = rd) -> a0 = palavra
tipo_j:
    srli t1, a0, 20
    andi t1, t1, 1
    slli t1, t1, 31
    srli t2, a0, 1
    andi t2, t2, 1023
    slli t2, t2, 21
    or   t1, t1, t2
    srli t2, a0, 11
    andi t2, t2, 1
    slli t2, t2, 20
    or   t1, t1, t2
    srli t2, a0, 12
    andi t2, t2, 255
    slli t2, t2, 12
    or   t1, t1, t2
    slli a1, a1, 7
    or   t1, t1, a1
    ori  a0, t1, 0x6F
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
