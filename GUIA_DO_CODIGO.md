# Guia do montador (`main.asm`)

Montador RISC-V RV32I escrito em Assembly para o RARS 1.6. Lê um `.asm` e gera
`<nome>_text.mif` e `<nome>_data.mif`.

## Como rodar

```
java -jar Rars16_Custom1.jar nc me main.asm pa caminho/arquivo.asm
```

- `nc` esconde o aviso de copyright, `me` mostra as mensagens de erro e `pa` passa o argumento ao programa.
- Sem o `pa ...`, o programa pergunta o nome do arquivo no console.
- Os dois `.mif` saem na pasta do arquivo de entrada, com o mesmo nome.
- Se houver erro de montagem, ele imprime `Erro na linha N: ...` e **não grava nenhum arquivo**.

## Visão geral

O programa lê o arquivo de entrada como texto e traduz **uma linha por vez**.

```
main
 ├─ pega o nome do arquivo (argumento ou console) e lê tudo para inbuf
 ├─ monta os nomes de saída (_text.mif e _data.mif)
 ├─ escreve o cabeçalho do MIF no buffer de saída
 ├─ para cada linha:  process_line
 └─ se não houve erro: grava _text.mif e _data.mif
```

### O que o `process_line` faz com uma linha

Exemplo: `loop: addi t0, t1, -4   # comentário`

1. Corta o comentário (`#`, ignorando `#` dentro de aspas).
2. Tira espaços do começo e do fim.
3. Se tem rótulo (`nome:`), pula o rótulo.
4. Se a linha começa com `.`, é diretiva: `.text` e `.data` trocam a seção, e `.word`, `.byte`, etc. vão para `data_dir`.
5. Se não é diretiva (`not_dir`): dentro da `.data` dá erro, e na `.text` ela é tratada como instrução.
6. Lê o mnemônico (`addi`) e procura na tabela de instruções.
7. Com o índice, consulta o formato, opcode, funct3 e funct7, e começa a montar a palavra de 32 bits.
8. Lê os operandos conforme o formato e encaixa cada campo nos bits certos.
9. Escreve a linha no buffer de saída:
   `00000003 : fffc0293;   % 9: addi t0, t1, -4 %`

## Registradores globais do montador

Só a `main` e o `process_line` usam estes. As sub-rotinas não mexem neles.

| Reg. | Uso |
|---|---|
| `s0` | ponteiro do início da linha atual |
| `s1` | ponteiro de escrita no buffer de saída |
| `s2` | número da linha atual (começa em 1) |
| `s3` | seção atual: 0 = `.text`, 1 = `.data` |
| `s4` | quantidade de erros |
| `s5` | índice da próxima instrução (contador de palavras do `.text`) |
| `s6` | limite do buffer de saída |
| `s8` (no `process_line`) | palavra de 32 bits sendo montada |
| `s7`, `s9`, `s10` (no `process_line`) | cursor no texto, imediato, fim útil da linha |
| `s11` | fim da linha atual |

Regra do projeto: sub-rotinas folha (`skip_ws`, `lookup`, `parse_*`...) usam só `a*` e `t*`.
As que chamam outras rotinas guardam `ra` e os `s*` na pilha.

## Rotinas auxiliares

| Rotina | Entrada | Saída |
|---|---|---|
| `skip_ws` | a0 = cursor, a1 = fim | a0 = primeiro caractere que não é espaço |
| `trim_end` | a0 = início, a1 = fim | a1 = fim sem espaços finais |
| `scan_ident` | a0 = cursor, a1 = fim | a0 = fim de `[A-Za-z0-9_.$]` |
| `lookup` | a0 = texto, a1 = tamanho, a2 = tabela, a3 = quantidade | a0 = índice ou -1 |
| `parse_reg` | a0 = cursor, a1 = fim | a0 = novo cursor, a1 = nº do registrador ou -1 |
| `parse_imm` | a0 = cursor, a1 = fim | a0 = novo cursor, a1 = valor, a2 = status (0 ok, 1 inválido, 2 não cabe em 32 bits) |
| `parse_mem` | a0 = cursor, a1 = fim | lê `imm(reg)`: a1 = imm, a2 = reg, a3 = status |
| `expect_char` | a0 = cursor, a1 = fim, a2 = caractere | a0 = depois do caractere, a1 = 0 ou -1 |
| `put_str`, `put_hex8`, `put_dec`, `put_range` | a0 = destino | a0 = novo destino |
| `report_error` | a0 = mensagem | imprime `Erro na linha N: ...` e soma em `s4` |

## A tabela única de instruções

Fica no `.data` do `main.asm`: `instnames` (os nomes) e quatro tabelas de bytes, todas **na mesma ordem**.
O índice da instrução é a posição dela nessas tabelas.

| Tabela | Conteúdo |
|---|---|
| `instnames` | nome (cada entrada ocupa 8 bytes, terminada em 0) |
| `fmttab` | formato dos operandos (ver abaixo) |
| `optab` | opcode |
| `f3tab` | funct3 |
| `f7tab` | funct7 (só importa em R e `srai`) |

Valores de `fmttab`:

| Valor | Formato | Exemplo |
|---|---|---|
| 0 | `rd, rs1, imm` | `addi t0, t1, -4` |
| 1 | `rd, rs1, shamt` | `slli t0, t0, 3` |
| 2 | `rd, imm(rs1)` | `lw t0, 8(sp)` |
| 3 | `jalr` | `jalr ra, t0, 0` |
| 4 | `rd, rs1, rs2` (tipo R) | `add t0, t1, t2` |
| 5 | `rs2, imm(rs1)` (tipo S) | `sw t0, 8(sp)` |

A constante `.eqv N_INST` guarda quantas instruções existem. O `lookup` usa esse valor.

## Como adicionar uma instrução que já tem formato pronto

Exemplo: `xori` já existe. Para um caso novo do mesmo formato, como `lh` (se não existisse):

1. Em `instnames`, acrescente no **final** o bloco
   ```
       .asciz "nome"
       .align 3
   ```
2. Acrescente **um valor no final** de cada tabela: `fmttab`, `optab`, `f3tab` e `f7tab`.
3. Some 1 em `.eqv N_INST`.
4. Teste (ver "Como testar").

Não precisa mexer no `process_line`, porque o formato já sabe ler os operandos.

## Como adicionar um formato novo (tipos U, B e J)

Os formatos 4 e 5 são o modelo. Em `process_line`, depois de achar o mnemônico:

```
li   t0, 4
beq  t3, t0, r_fmt      # formato R
li   t0, 5
beq  t3, t0, s_fmt      # formato S
j    i_start            # os demais caem no código do tipo I
```

Para um formato novo (por exemplo, 6 = tipo U):

1. Escolha um número novo em `fmttab` e coloque as instruções dele na tabela.
2. No bloco acima, inclua `li t0, 6` / `beq t3, t0, u_fmt`. O desvio precisa ficar **antes** do `j i_start`.
3. Escreva o bloco `u_fmt:`. Ele deve:
   - ler os operandos com `parse_reg`, `parse_imm`, `expect_char` e `parse_mem`;
   - checar o intervalo do imediato;
   - encaixar os campos em `s8` com `slli` e `or`;
   - terminar com `j i_finish`.
4. `i_finish` confere se não sobrou texto na linha e segue para a gravação no MIF.
5. Erros: use os rótulos `bad_reg`, `bad_sep`, `bad_imm`, `bad_range`, `bad_extra` e `bad_mem`.
   Se precisar de uma mensagem nova, crie `e_xxx` no `.data` e um rótulo `bad_xxx` como os existentes.

Modelo de bloco, tipo S (rs2, imm(rs1)):

```
s_fmt:
    mv   a0, s7              # cursor
    mv   a1, s10             # fim da linha
    call parse_reg           # rs2 -> a1 (-1 se inválido)
    bltz a1, bad_reg
    slli t0, a1, 20          # posição do rs2 na palavra
    or   s8, s8, t0
    mv   s7, a0              # avança o cursor
    ...
    j    i_finish
```

## Rótulos (beq, bne, jal) - ainda não implementado

`beq`, `bne` e `jal` usam o **deslocamento até o rótulo**, e o rótulo pode estar adiante no arquivo.
Por isso é preciso ler o arquivo duas vezes:

1. **Passada 1:** percorrer as linhas só para anotar `rótulo -> endereço` numa tabela.
   - `.text`: `0x00400000 + 4 * índice da instrução`.
   - `.data`: `0x10010000 + deslocamento em bytes`.
2. **Passada 2:** o `process_line` atual, que busca o rótulo na tabela e calcula
   `deslocamento = endereço_do_rótulo - endereço_da_instrução`.

A ideia é repetir o laço `line_loop` da `main` com um modo "só rótulos" na primeira volta.
Cuidado com a numeração do `s5` (índice da instrução) e do `s3` (seção), que precisam ser zerados entre as passadas.

## Formato dos arquivos de saída

Os dois seguem os exemplos do Aprender3 (quebra de linha LF).

- `_text.mif`: `DEPTH = 16384`, uma palavra por instrução, com comentário `% linha: texto original %`.
- `_data.mif`: `DEPTH = 32768`, sempre 1024 palavras (`000` a `3ff`), preenchidas com zero no que sobra.
  Os dados são empacotados em little-endian, byte a byte, e `.word` e `.half` alinham sozinhos.

## Como testar

O jeito mais seguro é comparar com o próprio RARS:

```
# 1. nosso montador
java -jar Rars16_Custom1.jar nc me main.asm pa teste.asm

# 2. o RARS monta o mesmo arquivo e despeja o .text em hexa
java -jar Rars16_Custom1.jar nc a dump .text HexText ref.txt teste.asm
```

Compare as palavras de `teste_text.mif` com `ref.txt` (o RARS usa maiúsculas e prefixo `0x`).
Para o `.data`, use `dump .data HexText`.

Dicas:
- Teste os extremos do imediato (`-2048`, `2047`, `0xFFFFFFFF`) e registradores por nome e por número (`x5`, `t0`).
- Teste os erros: instrução inexistente, falta de vírgula, imediato fora do intervalo.
- Não use nome de registrador como rótulo (`s1:`, `sp:`). O RARS aceita, mas descarta os dados.

## Estado atual

| Item | Status |
|---|---|
| Tipo R (10 instruções) | pronto |
| Tipo I (aritméticas, loads, `jalr`) | pronto |
| Tipo S (`sb`, `sh`, `sw`) | pronto |
| `.data` e `_data.mif` | pronto |
| `lui`, `auipc` (tipo U) | falta |
| `beq`, `bne` (tipo B) e `jal` (tipo J) | falta, precisa de rótulos |
| Relatório em PDF | falta |

Os arquivos em `scripts/` (`montador_tipoR/I/S.asm`, `read_input.asm`) são as versões separadas, mantidas por histórico.
O arquivo de entrega é o `main.asm`.
