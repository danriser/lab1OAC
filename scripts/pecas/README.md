# Peças do montador

Cada arquivo isola uma parte do `main.asm` e mostra, com casos de teste, que ela funciona.
As rotinas são cópias do `main.asm` (sem alteração). O que está fora delas é só a "bancada de teste":
um programa que chama a rotina com vários textos e imprime `obtido`, `esperado` e `OK` ou `ERRO`.

Rodar uma peça:

```
java -jar Rars16_Custom1.jar nc me scripts/pecas/01_registrador.asm
```

| Arquivo | Peça do montador | O que prova |
|---|---|---|
| `00_texto.asm` | `find_eol`, `skip_ws`, `trim_end`, `scan_ident` | andar pelo texto: fim de linha, espaços, nomes |
| `01_registrador.asm` | `lookup`, `parse_xnum`, `parse_reg` | `x0..x31` e nomes ABI viram o número do registrador |
| `02_imediato.asm` | `parse_imm` | decimal, negativo, `+`, hexa `0x`, e os erros (inválido, não cabe em 32 bits) |
| `03_memoria.asm` | `parse_mem` | `imm(reg)` de loads e stores, imediato opcional, limite de 12 bits |
| `04_tabela_instrucoes.asm` | `instnames` e tabelas, `lookup` | uma tabela só diz formato, opcode, funct3 e funct7 de cada instrução |
| `05_montagem_dos_campos.asm` | contas de `process_line` | como R, I, S, B, U e J encaixam os campos; as palavras esperadas vieram do RARS |
| `06_saida_hexa.asm` | `put_str`, `put_range`, `put_hex8`, `put_dec` | a linha do `_text.mif` sai igual à do arquivo de referência |
| `07_rotulos.asm` | `define_label`, `find_label` | tabela de rótulos e cálculo do deslocamento de `beq`/`jal` |
| `08_dados.asm` | `data_dir`, `emit_byte`, `align_data` | `.word`, `.half`, `.byte`, `.string` em little-endian e o alinhamento |

Na peça 7 aparece uma linha `Erro na linha 1: rotulo ja definido`. Ela é esperada: é o teste de rótulo repetido.

Se o `main.asm` mudar, estas cópias ficam desatualizadas. Para conferir o montador inteiro, o teste que vale é
montar `exemplo/exemplo-lab1.asm` e comparar com os `.mif` do Aprender3.
