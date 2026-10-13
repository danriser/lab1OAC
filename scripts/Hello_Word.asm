.data
msg: .asciz "Hello, World!\nRISC-V"


.text 
	la a0, msg	# a0 = endereco da string
	li a7, 4	# syscall 4 = imprir string
	ecall
	
	li a7, 10	#syscall 10 = encerrar progrma
	ecall

# Resumo de Syscall 
# 1 imprimi interio | a0 = número
# 2 imprimir string | a0 = endereco  
# 5 ler inteiro     | resultado em a0
# 10 encerrar
# 11 imprir caractere | a0 = codigo ASCII