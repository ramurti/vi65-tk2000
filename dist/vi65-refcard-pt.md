# VI65 para o TK2000 / MPF-II — cartão de referência

Português · [English](vi65-refcard.md)

Um editor de texto vi para o TK2000 e o Microprofessor II (MPF-II): 56 colunas × 24 linhas, maiúsculas e minúsculas, acentos
do português, arquivos em fita ou em disco (TKDOS 3.3). Baseado no VI65 de Soci/Singular (GPL v2).

## Para começar

| | |
|---|---|
| Da fita | `LOADT`, depois toque `vi65.wav` (TK2000 real) ou `vi65.ct2` (emulador); cerca de 1 min |
| Do disco | dê boot no TKDOS (`CALL 49408`), depois `BRUN VI65`; cerca de 15 s |
| Voltar ao texto depois de `:q` | `CALL 16387` |
| Começar de novo, vazio | `CALL 16384` |

O editor começa no **modo normal** (as teclas são comandos). `i`, `a`, `o`... passam ao **modo
de inserção** (as teclas são texto); **CTRL** pressionado e solto sozinho (ESC) volta ao modo
normal.

## O teclado do TK2000

| Tecla | Dá |
|---|---|
| letra | letra minúscula |
| SHIFT + letra | letra maiúscula |
| **CTRL sozinho** (pressionar e soltar) | **ESC** |
| CTRL + C | ESC também |
| CTRL + H | apaga para trás (backspace) |
| SHIFT + 1 ... 0 | `! " # $ % & ' ( ) *` |
| SHIFT + `:` `,` `.` `?` | `; < > /` |
| CTRL + SHIFT + I O P K L | `- = + ^ @` |
| setas | movem o cursor (também no modo de inserção) |

Não existem no teclado: `[ ] { } \ | ~ _` e a crase (acento grave).

## Movendo o cursor

**Caracteres**

| | |
|---|---|
| **setas** | esquerda, baixo, cima, direita |
| `h` `j` `k` `l` | esquerda, baixo, cima, direita |
| ESPAÇO / CTRL-H | direita / esquerda |
| CTRL-N CTRL-J / CTRL-P | baixo / cima |

**Linhas**

| | |
|---|---|
| `0` | início da linha |
| `^` | primeiro caractere que não é espaço |
| `$` | fim da linha |
| `+` RETURN | primeiro caractere da próxima linha |
| `-` | primeiro caractere da linha anterior |

**Procurar na linha**

| | |
|---|---|
| `f`*c* / `F`*c* | até o próximo / anterior *c* |
| `t`*c* / `T`*c* | até logo antes do próximo / logo depois do anterior *c* |

**Tela e arquivo**

| | |
|---|---|
| `H` `M` `L` | linha do topo, do meio, de baixo da tela |
| `gg` / `G` | primeira / última linha |
| *n*`G` | linha *n* |

**Marcas**

| | |
|---|---|
| `m`*x* | marca a linha como *x* (uma letra) |
| `'`*x* | vai para a linha marcada *x* |

Um número antes de um movimento o repete: `5j` desce 5 linhas.

## Rolagem

| | |
|---|---|
| CTRL-F / CTRL-B | uma tela para a frente / para trás (página abaixo / acima) |
| CTRL-D / CTRL-U | meia tela para baixo / para cima, com o cursor |
| CTRL-E / CTRL-Y | uma linha para baixo / para cima |

Linhas com mais de 56 colunas: `zh` `zl` rolam uma coluna para a esquerda / direita, `zH` `zL`
meia tela, `zs` `ze` põem o cursor no início / fim da tela; `g0` `gm` `g$` vão para a primeira
coluna, a do meio e a última da tela.

## Inserindo texto

| | |
|---|---|
| `i` / `a` | insere antes / depois do cursor |
| `I` / `A` | insere no início / fim da linha |
| `gI` | insere na coluna 1 |
| `o` / `O` | abre uma linha nova abaixo / acima |
| **ESC** (CTRL sozinho) | volta ao modo normal |

**No modo de inserção**

| | |
|---|---|
| CTRL-H | apaga o caractere antes do cursor |
| RETURN | quebra a linha |
| CTRL-E / CTRL-Y | copia o caractere abaixo / acima do cursor |
| setas | movem sem sair do modo de inserção |

## Acentos (no modo de inserção)

Digite o sinal e depois a letra, uma tecla após a outra:

| Teclas | Dão |
|---|---|
| `'` e depois `a e i o u` | á é í ó ú |
| `'` e depois `A E I O U` | Á É Í Ó Ú |
| `'` e depois `c` / `C` | ç / Ç |
| `"` e depois `a o` / `A O` | ã õ / Ã Õ |
| `'` ou `"` e depois ESPAÇO | só o `'` ou o `"` |
| `'` ou `"` e depois outra tecla | o sinal e depois a tecla: `it's` |

`'` é SHIFT + 7 e `"` é SHIFT + 2. Exemplo: **coração** = `c o r a ' c " a o`.

## Apagando e trocando

| | |
|---|---|
| `x` / `X` | apaga o caractere sob / antes do cursor |
| `dd` | apaga a linha |
| `D` | apaga até o fim da linha |
| `d`*movimento* | apaga até onde o movimento vai: `dj`, `d$`, `dG`, `dtx` |
| `J` | junta a próxima linha a esta |
| `s` | troca o caractere (apaga e entra em inserção) |
| `S` / `cc` | troca a linha inteira |
| `C` | troca até o fim da linha |
| `c`*movimento* | troca até onde o movimento vai: `c$`, `cfx` |

## Copiar e colar

| | |
|---|---|
| `yy` | copia a linha |
| `y`*movimento* | copia até onde o movimento vai: `y$`, `yj` |
| `p` / `P` | cola depois / antes do cursor |

Um número repete: `3dd` apaga 3 linhas, `2yy` copia 2.

## Busca

| | |
|---|---|
| `/`*texto* RETURN | procura *texto* para a frente |

## Arquivos

| | |
|---|---|
| `:w` *nome* | grava |
| `:w` | grava com o nome atual |
| `:e` *nome* | carrega (substitui o texto, sem perguntar) |
| `:wq` | grava e sai |
| `:q` | sai para o BASIC (o texto fica na memória; não avisa se há alterações não gravadas) |
| `:ene` | texto novo, vazio |
| `:f` *nome* | dá um nome ao texto, sem gravar |
| CTRL-G | mostra o nome do arquivo |

**Para onde vão os arquivos:** com o TKDOS carregado, `:w nome` e `:e nome` usam o disco, e
`:w t:nome`, `:e t:nome` a fita. Sem o TKDOS, tudo vai para a fita.

**Disco:** nomes de até 30 caracteres, gravados em maiúsculas (`nota` → `NOTA`); o `CATALOG`
os mostra com o tipo `T`. São arquivos de texto do TKDOS, que o BASIC consegue ler.

**Fita:** nomes de até 6 caracteres. Antes de `:w`, aperte REC no gravador; depois de `:e`,
aperte PLAY. Cabem vários arquivos numa fita, um depois do outro; `:e nome` pula os outros.
Cerca de 7 s por 1K de texto.

**Memória:** cerca de 22K de texto, ou 12K com o TKDOS.

**Linha de comando:** a seta para a esquerda ou CTRL-H apaga, ESC cancela, RETURN executa.

## Não disponível

Movimentos por palavra (`w b e`), desfazer (`u`), repetir (`.`), próxima ocorrência (`n`),
substituir caractere (`r`), registradores.
