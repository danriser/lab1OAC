.data
SEQ:  .word 1, 1, 0, 0, 0, 0, 0, 0, 0, 0
FILT: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.text
    lui  s0, 65552
    addi s0, s0, 0
    lui  s1, 65552
    addi s1, s1, 40
    addi t0, x0, 2
    addi t1, x0, 10

FIB_LOOP:
    slt  t2, t0, t1
    beq  t2, x0, FILTER_SETUP
    addi t3, x0, 2
    sll  t4, t0, t3

    addi t5, t0, -1
    sll  t5, t5, t3
    add  t5, s0, t5
    lw   a0, 0(t5)

    addi t6, t0, -2
    sll  t6, t6, t3
    add  t6, s0, t6
    lw   a1, 0(t6)

    add  a2, a0, a1
    add  t5, s0, t4
    sw   a2, 0(t5)

    addi t0, t0, 1
    jal  x0, FIB_LOOP

FILTER_SETUP:
    addi t0, x0, 1

FILT_LOOP:
    slt  t2, t0, t1
    beq  t2, x0, END
    addi t3, x0, 2
    sll  t4, t0, t3

    add  t5, s0, t4
    lw   a0, 0(t5)
    addi t6, x0, 1
    sll  a0, a0, t6

    addi t5, t0, -1
    sll  t5, t5, t3
    add  t5, s0, t5
    lw   a1, 0(t5)

    add  a2, a0, a1
    add  t5, s1, t4
    sw   a2, 0(t5)

    addi t0, t0, 1
    jal  x0, FILT_LOOP

END:
    jal  x0, END