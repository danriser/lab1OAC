.data
VET: .word 15, 42, 73, 21, 5, 99, 128, 3
N:   .word 8

.text
    lui  t0, 65552
    addi t0, t0, 0
    lw   t1, 32(t0)
    addi s0, x0, 0

MOD_LOOP:
    slt  t2, s0, t1
    beq  t2, x0, SORT_SETUP
    addi t4, x0, 2
    sll  t3, s0, t4
    add  t5, t0, t3
    lw   a0, 0(t5)

    addi a1, x0, 0
    addi t6, x0, 32
    addi a2, x0, 1

P_LOOP:
    andi a3, a0, 1
    add  a1, a1, a3
    srl  a0, a0, a2
    addi t6, t6, -1
    bne  t6, x0, P_LOOP

    lw   a0, 0(t5)
    add  a0, a0, a1
    sw   a0, 0(t5)

    addi s0, s0, 1
    jal  x0, MOD_LOOP

SORT_SETUP:
    addi s0, x0, 0

OUTER_LOOP:
    slt  t2, s0, t1
    beq  t2, x0, END
    addi s1, x0, 0
    sub  s2, t1, s0
    addi s2, s2, -1

INNER_LOOP:
    slt  t3, s1, s2
    beq  t3, x0, NEXT_I
    addi t4, x0, 2
    sll  t3, s1, t4
    add  t5, t0, t3
    lw   t6, 0(t5)
    lw   a0, 4(t5)

    slt  t3, t6, a0
    beq  t3, x0, NO_SWAP
    sw   a0, 0(t5)
    sw   t6, 4(t5)

NO_SWAP:
    addi s1, s1, 1
    jal  x0, INNER_LOOP

NEXT_I:
    addi s0, s0, 1
    jal  x0, OUTER_LOOP

END:
    jal  x0, END