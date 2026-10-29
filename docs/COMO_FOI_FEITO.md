# Como foi feito

A história do projeto, em linguagem simples, do pedido até a partida inteira a 60 quadros por segundo no Chrome. O detalhe técnico de cada passo está no [`RECOMPILADOR.md`](RECOMPILADOR.md) e no [`ESTADO.md`](../ESTADO.md); o método, no [`METODO.md`](METODO.md).

**Quem fez o quê.** O autor teve a ideia, escolheu o jogo, aprovou o plano, decidiu cada rumo e testou no Chrome a cada rodada, apontando o que estava errado. A IA (Claude, da Anthropic, no Claude Code) pesquisou, montou o plano, instalou as ferramentas, escreveu todas as correções, fez as medidas e a documentação. A base é o [ps2-web-recomp](https://github.com/snuri00/ps2-web-recomp), de snuri00, que já tinha o PS2 reimplementado para o navegador.

## Dia 1 · 15 de outubro de 2026

**De manhã, a escolha.** O ponto de partida foi a onda do REA, um repositório de engenharia reversa com agentes de IA que tinha acabado de passar de cem mil estrelas no GitHub. A primeira ideia, reconstruir o Duolingo, foi descartada: num serviço, o valor está no servidor, e o app sozinho não leva a lugar nenhum. Num jogo antigo, tudo está no disco. O escolhido foi o **PES 2012 de PS2**, com o Bomba Patch como bônus, e o caminho foi o mesmo do God of War II no navegador: **recompilar**.

**12h20, a bancada.** O compilador no Ubuntu, o Ghidra com o processador do PS2, o REA e o recompilador montados, cada instalação registrada em [`INSTALADOS.md`](INSTALADOS.md) para remover depois.

**12h40, o jogo liga e para.** O executável virou C++ e compilou. O jogo ligou, carregou os 12 módulos do disco e parou no primeiro pedaço de código que ele carrega do disco durante o jogo. O PES guarda boa parte do código em **pacotes num formato próprio da Konami** (`MWo3`, 30 deles com código), que entram e saem da memória conforme a tela, vários no mesmo endereço. O recompilador não conhecia esse formato.

**14h00, o tradutor aprende o formato da Konami.** Ler os pacotes, traduzir cada um no endereço dele e, durante o jogo, reconhecer **qual pacote está na memória agora** para chamar a tradução certa. Depois disso o jogo desenhou a tela de idioma, os avisos do memory card e o vídeo de abertura.

**15h00, a tela preta.** Depois do vídeo de abertura a tela ficava preta para sempre: o reprodutor de vídeo, ao terminar, desligava junto um aviso de "quadro novo" que o próprio jogo usava. Corrigido, apareceram a tela de título e os menus.

**15h20, o navegador.** A primeira versão para o Chrome, ainda lenta. A lentidão, achada no fim da tarde, não era do emulador: o `localhost` tentava primeiro o IPv6 e cada leitura do disco esperava 300 ms. Corrigido isso, o jogo chegou a 50 quadros por segundo dentro da partida.

**16h00 a 17h30, a partida.** Seleção de times, estádio, túnel, os times perfilados e, às 17h26, **uma partida inteira, do pontapé ao apito final, com gol e gravação no memory card**, sem faltar nenhum pedaço de código.

**18h30, o primeiro teste do autor.** O contador dizia 50 quadros por segundo, e a imagem travava muito. O contador estava certo: o monitor dele é de 120 Hz, e 50 quadros por segundo não dividem 120, então cada imagem fica ora duas, ora três atualizações da tela. O PES tem o modo de 60 Hz dentro do disco, mas nenhuma opção de menu chega nele (🔧 29/out: a gravação do boot com a versão atual mostrou a tela de modo de vídeo do próprio jogo, do `bootset.ovl`, com *NTSC (60Hz)* e *PAL (50Hz)*; as gravações antigas a pulavam com os toques programados. O que não chega no 60 é o menu de opções; a tela do início não foi conferida sem a instrução trocada). **Uma instrução trocada** (`config/pes2012-patches.txt`) e o jogo passou a iniciar em 60 Hz.

## Dia 2 · 16 de outubro

**O segundo teste do autor** achou três coisas: os jogadores entravam em campo **pretos**, os vídeos depois do logo da Konami **travavam** e a entrada dos jogadores **engasgava**.

- **Os jogadores pretos.** No navegador, o PS2 reimplementado divide o trabalho em linhas de execução separadas, como no console. Duas peças (as duas unidades vetoriais) dividiam uma anotação que deveria ser de cada uma, e uma apagava a da outra no meio do desenho. Cada uma ganhou a sua.
- **Os vídeos.** O reprodutor de vídeo do jogo pergunta ao chip de som "em que ponto você está?" centenas de vezes por quadro, e só decodifica imagem enquanto espera a resposta. No emulador a resposta voltava na hora, então ele quase nunca decodificava e jogava fora quase todas as imagens. No console essa resposta leva um tempinho; o emulador passou a levar também (40 microssegundos), e o vídeo voltou a ter as 30 imagens por segundo do arquivo.
- **A entrada.** Em duas trocas de câmera o jogo lê a tela de volta para a memória, e no navegador cada leitura esperava a placa de vídeo. A partir da segunda leitura seguida, a memória de vídeo inteira passou a vir uma vez só.

**O terceiro teste do autor:** *"pegou quase tudo, todas as cenas carregaram direitinho"*. Faltavam duas coisas: **o rosto de alguns jogadores e juízes virava um bico**, e havia **uma travadinha leve nas transições**, que podia ser do próprio PS2.

## Dia 3 · 17 de outubro

- **Os rostos.** O PES monta as expressões do rosto (boca, queixo, nariz) numa peça separada do PS2, uma das unidades vetoriais, e busca o resultado copiando direto da memória dela. O emulador lia esse endereço da memória principal, onde não tinha nada daquilo: os pontos do rosto que se mexem iam todos para o mesmo lugar e formavam o bico. Achar isso levou horas, rastreando para trás do ponto errado na tela até a cópia; a correção foi ensinar a cópia a ler a memória certa, como o console faz.
- **A travadinha.** Medindo quadro por quadro (e não a média por segundo, que escondia o problema), saíram duas coisas diferentes. Uma é **do próprio jogo**: a entrada roda a 30 imagens por segundo, e em algumas trocas de câmera o jogo escurece ou segura a imagem por alguns quadros, de propósito. A outra era **do emulador**: em duas fusões de câmera o jogo copia a tela em 224 linhas, e no navegador cada linha esperava uma ida e volta inteira, o que parava a imagem por 131 e 233 milésimos de segundo. Agora, quando ele lê a segunda linha, as seguintes já vêm prontas, e cada uma ainda é conferida com a leitura real. Depois disso, nenhum quadro da entrada passou de 45 milésimos.
- **A conferência.** A partida inteira de novo, do zero, 48 mil quadros sem faltar código, com gol, comemoração em close e memory card. E o teste do autor no Chrome: *"Ok, deu certo"*.

## Os números

| | |
|---|---|
| Do primeiro pedido ao último teste | menos de dois dias (15/out, 10h, a 17/out, 9h46), com uma pausa de uma noite |
| Commits | 32 até o teste final |
| Código traduzido | 831 arquivos de C++ (uns 216 MB), contando os 30 pacotes de código da Konami |
| Versão de navegador | um WebAssembly de ~79 MB |
| Velocidade no Chrome (RTX 3060) | 60 quadros por segundo nos vídeos, na entrada e na partida, com mais da metade do processador sobrando |
| Testes do autor no Chrome | um a cada rodada, cada um com o que estava errado nas palavras dele |
