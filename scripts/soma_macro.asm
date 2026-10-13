.data 

pede1: .asciz "Digite o primeiro número: "
pede2: .asciz "Digite o segundo número: "
res: .asciz "Resultado: "
nl: .asciz "\n"


.macro print_str(%rotulo)
    la   a0, %rotulo
    li   a7, 4
    ecall
.end_macro
    
.macro read_int_to(%register)
    li a7, 5
    ecall
    mv %register, a0
.end_macro

.macro soma2(%p1, %p2)
   mv a0, %p1
   mv a1, %p2
   jal SOMA
.end_macro

.macro print_int(%reg)
   mv a0, %reg
   li a7, 1
   ecall
.end_macro

.text 
main:
		print_str(pede1)
		read_int_to(t0)
		
		print_str(pede2)
		read_int_to(t1)
		
		# operacao
		soma2(t0, t1)
		mv t1, a0
		
		print_str(res) 
		mv a0, t1
		
		li a7, 1 # imprimir inteiro
		ecall
		
		j FIM
		
	
SOMA:
   # SOMA DOIS NÚMEROS E COLOCA O RESUTLTADO T0
   # A0: int
   # A1: int
   # ret A0 RESULTADO
   add a0, a0, a1
   ret	
FIM:	
   li a7, 10
   ecall		