# VI65 para o TK2000 / MPF-II

Português · [English](README.en.md)

Um editor de texto vi para o TK2000: o [VI65](https://sourceforge.net/projects/vi65/) de
Soci/Singular (2010-2013, GPL v2), montado a partir da sua versão para a alta resolução do
Apple II. O TK2000 não tem modo texto; o VI65 desenha sua própria fonte 5 × 8 na tela de alta
resolução: **56 colunas × 24 linhas**, com maiúsculas e minúsculas.

Ele também é para o **Microprofessor II (MPF-II)** da Multitech, do qual o TK2000 é uma cópia
brasileira. Até agora só foi testado num emulador de TK2000, e a parte de disco precisa do
TKDOS, o sistema de disco do TK2000.

## O que esta versão acrescenta ao VI65

Além do VI65 original (detalhes nas seções abaixo):

- **Roda no TK2000:** carrega da fita (`LOADT`) ou de um disco TKDOS (`BRUN VI65`) e começa com
  um texto vazio.
- **O teclado do TK2000:** letras minúsculas, todos os símbolos que o teclado tem (SHIFT e
  CTRL + SHIFT), repetição de tecla, e as teclas digitadas enquanto a tela é redesenhada são
  guardadas em vez de perdidas.
- **ESC sem tecla ESC:** CTRL pressionado e solto sozinho (ou CTRL-C).
- **Acentos do português:** `'` e `"` antes de uma letra dão á é í ó ú ç ã õ e as maiúsculas,
  com letras desenhadas para a fonte de 56 colunas.
- **Arquivos em fita:** `:w` e `:e` no formato de fita do próprio TK2000; vários arquivos numa
  fita; dá para editar enquanto o arquivo ainda carrega; são texto puro, que o BASIC também
  carrega.
- **Arquivos em disco com o TKDOS 3.3:** `:w` e `:e` usam o disco quando o TKDOS está carregado,
  e `t:nome` continua usando a fita; são arquivos de texto do TKDOS, que programas em BASIC leem
  e gravam.
- **Rolagem de meia tela:** CTRL-D e CTRL-U (CTRL-F e CTRL-B, uma página inteira, já existiam).
- **A seta para a esquerda apaga** nas linhas de `:` e `/`.
- **Sair e voltar:** `:q` volta para o BASIC com a tela limpa e o texto guardado na memória, e
  `CALL 16387` o traz de volta, com o cursor e o nome do arquivo.
- **Pronto para usar:** `dist/` tem a fita (`vi65.ct2`, e `vi65.wav` com `make dist`), um disco
  TKDOS com o editor (`vi65.dsk`) e cartões de referência em português e inglês.

## Carregar e usar

[`dist/vi65-refcard-pt.md`](dist/vi65-refcard-pt.md) é um cartão de referência com todos os
comandos, as teclas e os acentos, para ler ou enviar separado deste README (em inglês:
[`dist/vi65-refcard.md`](dist/vi65-refcard.md)).

No emulador: F2 -> inserir `dist/vi65.ct2`, digitar `LOADT`, RETURN, F6 (play). Ele começa
sozinho depois de cerca de um minuto. Num TK2000 de verdade: `LOADT` e tocar `dist/vi65.wav`
(gerado por `make dist`, fora do git).

O editor começa com uma linha vazia no modo normal, como o vi. O VI65 tem uma parte do vi
(`reference/vi65/bin/doc.txt`; o manual copia o texto do VIM, o código tem menos):

- inserção: `i a I A o O` (CTRL sozinho ou CTRL-C para sair), CTRL-H apaga, as setas movem,
  CTRL-E / CTRL-Y inserem o caractere de baixo/de cima;
- apagar e trocar: `x X D C s S J`, `d c y` + um movimento (`dd`, `d$`, `cc`, `yy`), `p P`;
- movimentos: `h j k l` (e as setas), `0 ^ $ |`, `f t F T`, `H M L`, `G gg`, `+ -` RETURN,
  ESPAÇO, marcas (`m` e depois `'` ou a crase, que o TK2000 não tem); contagens (`3dd`, `5j`);
- rolagem: CTRL-F, CTRL-B, CTRL-D, CTRL-U (meia tela, acrescentados para o TK2000), CTRL-E,
  CTRL-Y, comandos `z`;
- busca com `/`, CTRL-G (informação do arquivo);
- `:e :ene :f :w :wq :q`: arquivos em disco ou fita (abaixo).

Não existem no VI65: movimentos por palavra (`w b e`), desfazer (`u`), `n`, `r`, `.`.

Conferido no emulador até agora: inserção, RETURN, CTRL-C, CTRL-H, seta para a esquerda no modo
de inserção e na linha de `:`, todas as letras e símbolos com SHIFT, os símbolos com
CTRL+SHIFT, `x dd yy p G gg`, busca com `/`, repetição de tecla, `:w` e `:e` em fita (um arquivo
de 9K com 300 linhas carregado, editado, gravado e comparado), um arquivo grande demais, `:q` e
`CALL 16387`; com o TKDOS: `:w` e `:e` em disco, um nome que não existe, um arquivo gravado por
um programa em BASIC, um arquivo lido por um, `t:` para a fita, `:q`, CATALOG e `CALL 16387`.

### Arquivos em disco (TKDOS 3.3)

Primeiro dê boot no TKDOS (no emulador: F2 -> inserir o disco, depois `CALL 49408`), depois
carregue o editor: do mesmo disco com `BRUN VI65` (cerca de 15 s), ou da fita como acima.
`make dist` gera `dist/vi65.dsk`, o disco mestre do TKDOS (`MASTER=`, por padrão
`~/pessoal/tkdos2000.dsk`) com o VI65 acrescentado por `tools/mkdsk.py`, e um texto para
experimentar: `:e guerra1` abre o capítulo I de *A Arte da Guerra* (`samples/guerra1.txt`,
traduzido para o português da versão inglesa de Lionel Giles, de 1910, que está em domínio
público). O editor percebe o TKDOS e então:

- **`:w nome`** e **`:e nome`** usam o disco; **`:w t:nome`** e **`:e t:nome`**, a fita.
- Os nomes são como o TKDOS os aceita (até 30 caracteres), em maiúsculas: `:w notas` grava
  `NOTAS`.
- `:e` de um nome que não está no disco mostra "not found"; outros erros de disco mostram
  "i/o error".
- Os arquivos são arquivos de texto do TKDOS, como o `PRINT` para um arquivo os grava (CR depois
  de cada linha, bit 7 ligado): programas em BASIC os leem com `INPUT`, e o editor lê os deles.
  As letras acentuadas ficam gravadas como os códigos de controle 1-26 (o BASIC os vê assim); o
  BASIC do TK2000 mostra as letras minúsculas como outros sinais.
- Memória: o editor faz **MAXFILES 1** (abre um arquivo de cada vez); o texto fica em
  `$66B4-$98FF`, cerca de 12K (22K sem o TKDOS). Rode MAXFILES de novo depois de `:q` se um
  programa em BASIC precisar de mais arquivos.
- Gravar umas poucas linhas leva cerca de 6 s (o TKDOS esvazia o arquivo antigo antes: OPEN,
  DELETE, OPEN).

### Arquivos em fita

Sem o TKDOS (ou com `t:` antes do nome):

- **`:w nome`** grava o texto na fita: aperte REC (e PLAY) no gravador antes. A linha de estado
  mostra "writing the tape" e depois "saved".
- **`:e nome`** carrega um arquivo: digite o comando e aperte PLAY. A linha de estado mostra
  "reading the tape" até o arquivo ser encontrado e lido; as linhas aparecem à medida que são
  lidas, e já dá para mover e editar enquanto o resto carrega.
- O nome é cortado em **6 caracteres, em maiúsculas** (os nomes de fita do TK2000): `:w notas`
  grava `NOTAS`. Os arquivos são texto puro (CR depois de cada linha), então `LOADT NOTAS` no
  BASIC também os lê, e os outros arquivos da fita são pulados como o LOADT faz.
- **Não há como cancelar uma leitura** a não ser com RESET (ela espera a fita, como o LOADT). Um
  arquivo maior que a memória livre (cerca de 22K, ou 12K com o TKDOS, menos 5 bytes por linha)
  é recusado com "out of memory" antes de ser lido; pare a fita nesse caso.
- `:e` substitui o texto (o VI65 não pergunta sobre alterações não gravadas).
- **Vários arquivos numa fita:** cada `:w` é gravado depois do anterior (não rebobine entre
  eles); `:e nome` pula os outros até achar `nome`.
- **Velocidade:** cerca de 7 s por 1K de texto (os bits de 250/500 µs da ROM): um arquivo de 10K
  leva cerca de 70 s depois que o gravador chega nele.

No emulador, o que o TK2000 grava vai para `recorded.ct2`, ao lado da fita inserida (a gravação
do próprio emulador, desde nov/2026): cada gravação é acrescentada a ele, então ele guarda todos
os arquivos gravados, em ordem, como uma fita de verdade; insira-o para carregá-los de volta.
`tools/ct2txt.py FITA.ct2` grava os arquivos de uma fita como `.txt`; `tools/txt2ct2.py
ARQUIVO.txt NOME SAIDA.ct2` transforma um texto numa fita para o `:e`.

### Sair e voltar

`:q` volta para o BASIC com a tela limpa; o texto continua na memória. **`CALL 16387`** volta ao
editor com o texto, o cursor e o nome do arquivo como estavam (`CALL 16384` começa de novo,
vazio). Programas em BASIC, `HGR2` e `NEW` não mexem na área do texto (`$66B4-$BEFF`, ou até
`$98FF` com o TKDOS), mas carregar outro programa por cima dela, sim.

### Teclas

O TK2000 não tem teclas minúsculas nem ESC; o teclado (`vi65/tk.asm`) fica assim:

| Tecla | Dá |
|---|---|
| uma letra | a letra minúscula (os comandos do vi) |
| SHIFT + letra | a letra maiúscula |
| SHIFT + 1 2 3 4 5 6 7 8 9 0 | `! " # $ % & ' ( ) *` |
| SHIFT + `:` `,` `.` `?` | `; < > /` |
| CTRL + SHIFT + I O P K L | `- = + ^ @` (os símbolos que o TK2000 tem impressos nelas) |
| **CTRL sozinho** (pressionar e soltar) | **ESC** (sai do modo de inserção, como no vim) |
| CTRL + C | ESC também |
| **CTRL + H** | **apaga para trás**: apaga o caractere antes do cursor no modo de inserção e nas linhas de `:` e `/` |
| CTRL + letra | o código de controle (CTRL-F, CTRL-B, CTRL-E, CTRL-Y...) |
| setas | movem o cursor, também no modo de inserção; nas linhas de `:` e `/` a seta para a esquerda apaga |

Uma tecla segurada se repete depois de 0,5 s, 15 vezes por segundo. As teclas digitadas enquanto
a tela é redesenhada são guardadas (até 8) e tratadas depois: o TK2000 não guarda a última tecla
apertada, e digitar rápido perdia teclas antes disso.

Faltam no teclado: `[ ] { } \ | ~ _` e a crase.

### Acentos

No modo de inserção, `'` (SHIFT + 7) e `"` (SHIFT + 2) esperam a próxima tecla, uma depois da
outra:

| Teclas | Dão |
|---|---|
| `'` e depois a e i o u (ou A E I O U) | á é í ó ú (Á É Í Ó Ú) |
| `'` e depois c (ou C) | ç (Ç) |
| `"` e depois a o (ou A O) | ã õ (Ã Õ) |
| `'` ou `"` e depois ESPAÇO | só o `'` ou o `"` |
| `'` ou `"` e depois outra tecla | o sinal e depois a tecla (`it's`) |

`coração` é `c o r a ' c " a o`. O texto guarda as letras em Latin-1 (`á` = `$E1`), também na
fita; `tools/txt2ct2.py` e `tools/ct2txt.py` convertem de e para UTF-8. As maiúsculas acentuadas
são desenhadas um pouco menores, para o acento caber nas 8 linhas de um caractere
(`tools/accents.py` faz as letras a partir das da fonte: `vi65/latin1.fnt`; `--preview PNG` as
desenha). No emulador num Mac, um layout de teclado com teclas mortas (Brasileiro - Pro: SHIFT +
6 é `^`) pode engolir teclas; `'` e `"` são SHIFT + 7 e SHIFT + 2 nele, que não são teclas
mortas. Não há acentos nas linhas de `:` e `/`, nem â ê ô à por enquanto (as letras existem, as
teclas não).

## Ainda não feito

- Testado só no emulador.

## Montagem

Precisa do 64tass (`brew install tass64`; Debian/Ubuntu `apt install 64tass`), do Python 3 e,
para o executor de testes, do código-fonte do emulador e do SDL2.

```sh
make            # build/vi65.ct2
make dist       # dist/vi65.ct2, dist/vi65.dsk e dist/vi65.wav
make build/run  # o emulador sem tela (EMU = o src/ do emulador, por padrão ~/pessoal/tk2000/src)
```

`build/run build/vi65.ct2 -t 80 $(python3 tools/keys.py 66 'ihello{esc}') -s 79:shot.ppm` digita
teclas em tempos do emulador e tira uma foto da tela (`tools/keys.py` explica a sintaxe das
teclas; o editor fica pronto cerca de 63 s depois do LOADT). `-r rec.ct2` grava o que ele salva
em fita, `-i TEMPO:ARQUIVO.ct2` insere uma fita e a toca (`tools/harness/run.cpp`). Com um `.dsk`
no lugar da fita ele dá boot no disco (`CALL 49408`); depois `-T '35:LOADT\n' -i
36:build/vi65.ct2` carrega o editor (pronto em cerca de 112 s). Os despejos de memória (`-m`)
também mostram os registradores da CPU.

## Como a versão do TK2000 difere da do Apple II

O código é o trunk do svn do VI65 (`vi65/`, o original em `reference/vi65/code/`), montado com
`TARGET=2 GFX=2 TK=1`. Toda mudança está dentro de `.if TK`:

- carrega em `$4000` (a versão do Apple em `$0C00`); o texto usa `$66B4-$BEFF` (incluindo a
  página 2 da alta resolução, que nunca é mostrada): cerca de 22K; com o TKDOS, até o HIMEM dele;
- arquivos em disco (`tk.asm`): como na versão do Apple (comandos do DOS impressos depois de
  CTRL-D), mais o que o TKDOS precisa para aceitá-los de um programa: os ganchos dele ligados
  (`$3EA`), o estado de saída no início de uma linha (`$AA52`), o BASIC rodando (`$76`, e o
  prompt `$33` diferente de `>`), os erros dele pelo ONERR (`$D8`, `$9D5A`; o código vem em X),
  tudo restaurado depois de cada uso;
- tela: monocromática (`$C051`; a fonte tem pixels isolados) e página 1; os `$C052`/`$C057` do
  Apple são o relé da fita no TK2000 e não são tocados;
- teclado: `tk.asm` varre a matriz no lugar do latch `$C000` do Apple, e a tela a consulta entre
  as linhas (`tkpoll`) para não perder teclas durante o redesenho;
- a seta para a esquerda dá o código 31 (`k_cursorleft`) e move (nas linhas de `:` e `/` ela
  apaga); no Apple ela é CTRL-H, que apaga no modo de inserção; a seta para a direita dá 30
  (`k_cursorright`), e não o CTRL-U do Apple, que aqui rola meia tela para cima;
- teclas CTRL: `k_control` = 96, porque o código da versão do Apple é ASCII ("e"-96 = CTRL-E);
- começa com uma linha vazia (a versão do Apple carrega `doc.seq` do disco ao começar);
- arquivos em fita com as rotinas `SAVET`/`LOADT` da ROM (`$EC9A`, `$EDAE`) no lugar do DOS
  (`tk.asm`): `:w` escreve o texto na memória livre e grava a partir dali; `:e` o carrega abaixo
  de `$BF00` (o endereço do cabeçalho é trocado enquanto a ROM imprime o nome do arquivo pelo
  CSW, o que também tira as mensagens da ROM da tela) e pega as linhas dali como a versão do
  Apple as pega do DOS, com o alloc usando só a memória já lida;
- `:q` pula para o vetor de reset; `CALL 16387` (`$4003`) retoma, trocando a página zero de
  volta.

## Como o VI65 desenha as letras

Sem tabela pronta: a fonte tem 8 bytes por caractere; 7 caracteres de 5 pixels enchem
exatamente 5 bytes da tela, e o código é desenrolado para cada uma das 7 posições, deslocando
cada linha da letra para o lugar e levando o que sobra para o byte seguinte. As linhas só são
redesenhadas quando mudam.

## Experiências anteriores

O projeto começou como uma ideia de 80 colunas (`tools/font.py`, `tools/preview.py`: uma fonte
3 × 5, dois caracteres por byte); com 3,5 pixels por caractere, um par de letras sim, outro não
fica encostado, então ele passou para o VI65. `tools/vi65preview.py` compara as fontes do VI65
em 46, 56 e 70 colunas.

## Licença

O VI65 é GPL v2 (`vi65/COPYING`); as mudanças para o TK2000 estão sob a mesma licença.
