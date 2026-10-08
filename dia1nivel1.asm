.data
VETOR:    .word 15, 25, 35, 45
RESULT:   .word 0

.text
main:
lui  t0, 65552
addi t0, t0, 0
addi t1, x0, 4
addi t2, x0, 0
LOOP:
lw   t3, 0(t0)
add  t2, t2, t3
addi t0, t0, 4
addi t1, t1, -1
bne  t1, x0, LOOP
lui  t4, 65552
addi t4, t4, 16
sw   t2, 0(t4)
FIM:
jal  x0, FIM