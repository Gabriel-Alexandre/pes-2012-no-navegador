# O método

Este projeto não foi feito no chute. Cada defeito passou pelas mesmas etapas: reproduzir sempre igual, medir, achar a causa no comportamento do console, corrigir de forma geral (não só para o PES), conferir com o mesmo número de antes e rodar a partida inteira de novo. As técnicas abaixo são as que a engenharia de software, a engenharia reversa e a comunidade de preservação de jogos já usam e validam há anos. A IA (Claude) foi a ferramenta que executou cada etapa; as decisões de rumo e os testes no Chrome foram do autor.

| # | Técnica | De onde vem | Onde foi usada aqui |
|---|---|---|---|
| 1 | **Recompilação estática**: traduzir o código de máquina do jogo, instrução por instrução, para outra plataforma, uma vez só, em vez de interpretar enquanto roda | a comunidade de preservação de jogos (o N64Recomp, de 2024, popularizou o caminho; o [ps2-web-recomp](https://github.com/snuri00/ps2-web-recomp) é a versão para o PS2 no navegador) | a base inteira do projeto |
| 2 | **O console como gabarito** | o mesmo princípio dos emuladores de referência, como o PCSX2: quando a dúvida é "o que o PS2 faz aqui?", a resposta é o comportamento documentado do hardware, não o que parece certo | o DMA que lê a memória das unidades vetoriais (os rostos); o tempo de ida e volta entre os dois processadores (os vídeos); o custo de uma chamada ao sistema |
| 3 | **Reprodução determinística** | depuração de software: um defeito que não se repete não se conserta | estados salvos (`antes-tunel.state`, `partida60.state`) e toques programados levam sempre ao mesmo quadro; o quadro 6.899 mostrava o mesmo rosto em bico em toda rodada |
| 4 | **Medir antes de mudar, e conferir com o mesmo número depois** | engenharia de desempenho | imagens diferentes por quadro de vídeo (34 antes, 439 depois); o tempo de cada quadro, não a média por segundo (a média escondia paradas de 131 e 233 ms) |
| 5 | **Rastrear para trás a partir do sintoma** | engenharia reversa: o "ponto de observação" (*watchpoint*) que avisa quem escreveu num endereço | os rostos: do vértice errado na tela até o pacote de dados, até a cópia, até o endereço que o emulador lia no lugar errado |
| 6 | **Hipóteses concorrentes, uma derrubada por vez** | método científico | a "travadinha": separar o que é pausa do próprio jogo (o jogo segura a imagem de propósito) do que é custo do emulador (a espera por leitura de tela) |
| 7 | **Teste diferencial**: dois caminhos que deveriam dar o mesmo resultado, comparados | teste de software; é como o próprio REA confere uma função reconstruída contra a original | o desenho por software contra o WebGPU (0 pixels diferentes); a leitura antecipada contra a leitura real (600+ faixas, nenhuma diferença); uma linha de execução contra duas (o 3D preto) |
| 8 | **Regressão longa a cada mudança** | integração contínua | a partida inteira do zero, 48 mil quadros (uns 13 minutos de jogo), sem faltar código, depois de cada correção grande |
| 9 | **Cada mudança escrita com o porquê** | registro de decisões de engenharia | [`RECOMPILADOR.md`](RECOMPILADOR.md): o arquivo, a mudança, a causa e a medida |

## O que fica fora

- **O código do jogo.** Nada do disco entra no repositório (técnica 1 traduz, mas a tradução é do dono do jogo). Ver o README.
- **O REA e o Ghidra.** Foram instalados e configurados no primeiro dia (o projeto nasceu da onda do REA), mas o diagnóstico não precisou deles: os defeitos apareceram no comportamento do PS2 reimplementado, e foram achados com as técnicas 3 a 7 no próprio código do recompilador.
