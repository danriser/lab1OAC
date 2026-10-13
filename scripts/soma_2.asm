.data 

pede1: .asciz "Digite o primeiro número: "
pede2: .asciz "Digite o segundo número: "
res: .asciz "Resultado: "
nl: .asciz "\n"

.text 
	main:
		la a0, pede1
		li a7, 4
		ecall
		
		li a7, 5 # syscal ler inteiro = escreve em a0
		ecall
		mv t0, a0