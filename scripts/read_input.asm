.data
prompt:     .asciz "Digite o caminho do arquivo: "
caminho:    .space 128             # Buffer para até 128 caracteres
conteudo:   .space 256             # Buffer para ler dados do arquivo
erro_msg:   .asciz "Erro ao abrir o arquivo.\n"

.text
main:
    # 1. Imprime a mensagem pedindo o caminho
    la a0, prompt
    li a7, 4
    ecall

    # 2. Lê a string do usuário (syscall 8)
    la a0, caminho
    li a1, 128
    li a7, 8
    ecall

    # 3. Remove o '\n' da string lida (essencial para abrir arquivos!)
    la t0, caminho
limpa_newline:
    lb   t1, 0(t0)                 # Carrega o byte atual
    beqz t1, fim_limpeza           # Se chegou no fim (\0), sai
    li   t2, 10                    # ASCII 10 = '\n'
    beq  t1, t2, substitui_nulo    # Se achou '\n', vai trocar por '\0'
    addi t0, t0, 1                 # Próximo caractere
    j    limpa_newline

substitui_nulo:
    sb   zero, 0(t0)               # Escreve '\0' por cima do '\n'

fim_limpeza:
    # 4. Abre o arquivo usando o caminho limpo (syscall 1024 - open)
    la a0, caminho                 # Ponteiro para a string limpa
    li a1, 0                       # Flags: 0 = somente leitura (read-only)
    li a7, 1024                    # Syscall de abrir arquivo
    ecall                          # Retorna o descritor (file descriptor) em a0

    # Verifica se deu erro (a0 < 0 indica erro)
    bltz a0, deu_erro
    mv s0, a0                      # Salva o descritor de arquivo em s0

    # 5. Lê os primeiros 255 bytes do arquivo (syscall 63 - read)
    mv a0, s0                      # Descritor do arquivo
    la a1, conteudo                # Buffer de destino
    li a2, 255                     # Quantidade de bytes a ler
    li a7, 63
    ecall

    # 6. Imprime o conteúdo lido na tela (syscall 4)
    la a0, conteudo
    li a7, 4
    ecall

    # 7. Fecha o arquivo (syscall 57 - close)
    mv a0, s0
    li a7, 57
    ecall

    j encerra

deu_erro:
    la a0, erro_msg
    li a7, 4
    ecall

encerra:
    li a7, 10                      # Finaliza execução
    ecall