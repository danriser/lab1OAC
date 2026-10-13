.data
MAT:    .word 15, 31, 7, 255, 63, 3, 1, 0, 4095
RES:    .word 0, 0, 0, 0, 0, 0, 0, 0, 0
SCALAR: .word 5

.text
    lui  s0, 65552
    addi s0, s0, 0
    lui  s1, 65552
    addi s1, s1, 36
    addi s3, x0, 0

OUTER:
    slti t0, s3, 9
    beq  t0, x0, END
    addi t6, x0, 2
    sll  t1, s3, t6
    add  t2, s0, t1
    lw   a0, 0(t2)

    addi a1, x0, 0
    addi t3, x0, 32
    addi t5, x0, 1

POP_LOOP:
    andi t4, a0, 1
    add  a1, a1, t4
    srl  a0, a0, t5
    addi t3, t3, -1
    bne  t3, x0, POP_LOOP

    lui  t4, 65552
    lw   a0, 72(t4)

    jal  ra, MULT
    addi t6, x0, 2
    sll  t1, s3, t6
    add  t5, s1, t1
    sw   a0, 0(t5)

    addi s3, s3, 1
    jal  x0, OUTER

MULT:
    addi t0, x0, 0
    addi t1, x0, 32
    addi t6, x0, 1

M_LOOP:
    andi t2, a1, 1
    beq  t2, x0, SHIFT
    add  t0, t0, a0

SHIFT:
    sll  a0, a0, t6
    srl  a1, a1, t6
    addi t1, t1, -1
    bne  t1, x0, M_LOOP
    add  a0, t0, x0
    jalr x0, 0(ra)

END:
    jal  x0, END