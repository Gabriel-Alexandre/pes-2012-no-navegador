# PES 2012 no navegador

O **PES 2012 de PlayStation 2** rodando dentro do Chrome, a 60 quadros por segundo, do menu até a partida inteira, com gol, replay e memory card. Sem emulador instalado: o código do jogo é **traduzido** para C++ e compilado para WebAssembly, e o resto do PS2 (o sistema, as unidades vetoriais, o chip gráfico em WebGPU, o som) é reimplementado em volta dele. É a técnica chamada **recompilação estática**.

O trabalho foi feito por uma IA (Claude, da Anthropic) sob a direção do autor, em cima do [ps2-web-recomp](https://github.com/snuri00/ps2-web-recomp), o recompilador aberto que já tinha levado o Gran Turismo 4 e o God of War II ao navegador. O que este repositório acrescenta é o que o PES precisou para funcionar: as correções no recompilador, os ajustes do jogo e o passo a passo.

> *English, in short:* PES 2012 (PS2, SLES-55658) running in Chrome at 60 fps through static recompilation, built on [ps2-web-recomp](https://github.com/snuri00/ps2-web-recomp). No game data here: bring your own disc image and run `scripts/preparar-pes.sh`. What had to change for PES is in [`docs/RECOMPILADOR.md`](docs/RECOMPILADOR.md).

## ⚠️ Antes de tudo: não tem nada do jogo aqui

Este repositório **não tem nenhum arquivo do PES 2012**: nem a imagem do disco, nem o executável, nem o código traduzido. Ele tem só o recompilador, as correções e os scripts. **Para usar, você precisa da sua própria cópia do jogo**, feita a partir de um disco seu.

O C++ e o WebAssembly que o recompilador gera a partir do disco **são uma tradução do jogo e pertencem à Konami**: ficam na sua máquina, e não se publicam nem se hospedam. Um gancho de commit (`scripts/verificar-sem-jogo.py`) trava qualquer arquivo do jogo que tente entrar no git.

PES e Pro Evolution Soccer são marcas da Konami; PlayStation é marca da Sony Interactive Entertainment. Este projeto não tem relação com nenhuma das duas.

## O que funciona

| | |
|---|---|
| Menus, vídeos de abertura, seleção de times | ✅ |
| Entrada dos jogadores pelo túnel e os times perfilados no campo | ✅ com os rostos certos |
| Partida inteira, do pontapé ao apito final, com gol, replay e comemoração | ✅ |
| Gravar no memory card (fica guardado no navegador) | ✅ |
| Velocidade | **60 quadros por segundo** no Chrome com uma placa de vídeo comum (medido numa RTX 3060), com folga |
| Controle | teclado e controle de PC (tabela abaixo) |

Testado com a versão **SLES-55658** (PAL europeia, menus em espanhol, italiano, **português** e grego). O jogo inicia em 60 Hz por uma correção de uma instrução (`config/pes2012-patches.txt`). Outras versões do PES 2012 podem funcionar, mas não foram testadas.

## Como usar

**Do que você precisa:** um computador com **Windows 11 e o Ubuntu 22.04 no WSL** (ou um Linux), uns **10 GB livres**, o **Chrome**, o **Python** no Windows e a **imagem do seu disco** (`.iso`, ou um `.7z` ou `.zip` com ela dentro).

**1. Clone dentro do Ubuntu** (não em `/mnt/c`: compilar lá é muito mais lento):

```bash
git clone https://github.com/Gabriel-Alexandre/pes-2012-no-navegador.git ~/pes-2012-no-navegador
cd ~/pes-2012-no-navegador
```

**2. Instale o que o recompilador precisa** (uma vez só; pede a senha do Ubuntu e registra cada pacote em `docs/apt-instalados.txt`, para remover depois com `scripts/desinstalar-ubuntu.sh`):

```bash
sudo bash scripts/instalar-ubuntu.sh
```

**3. Prepare o jogo a partir do seu disco.** O script confere a imagem, coloca as correções deste repositório no lugar e roda o recompilador (tradução, uma rodada de teste e as versões de navegador e nativa). A primeira vez baixa o Emscripten (~1 GB) e leva uns 20 minutos:

```bash
bash scripts/preparar-pes.sh "/mnt/c/Users/VOCE/Downloads/PES 2012.iso"
```

**4. Jogue.** No Windows, num PowerShell, na pasta do repositório (dá para abrir pelo Explorador em `\\wsl.localhost\Ubuntu-22.04\home\VOCE\pes-2012-no-navegador`):

```powershell
powershell -ExecutionPolicy Bypass -File scripts\servir-no-windows.ps1
```

Depois abra **http://localhost:8620** no Chrome e clique em **Start**. O servidor só escuta no próprio computador. Num Linux com WebGPU, sem o Windows: `python3 recomp/scripts/serve.py recomp/build/web-pes2012 recomp/games/pes2012/disc.iso`.

⚠️ Por que servir pelo Windows: servida de dentro do Ubuntu, cada leitura do disco passa pelo repasse de rede do WSL e o jogo fica esperando. E dentro do Ubuntu do WSL não há placa de vídeo para o WebGPU, então a janela nativa (`recomp/build/native-pes2012/ps2run`) desenha por software e fica lenta: serve para conferir, não para jogar.

| Tecla | PS2 |
|---|---|
| Setas | direcional |
| Z / X / A / S | ✕ / ◯ / ▢ / △ |
| Q / W · 1 / 2 | L1 / R1 · L2 / R2 |
| Enter / Backspace | Start / Select |
| I J K L | analógico esquerdo |
| F | tela cheia |

O vídeo de abertura do jogo é longo de fábrica (~2,5 min) e se pula com Start ou ✕. Controle de PC funciona pelo navegador, com vibração e pressão dos botões.

## Como foi feito

| Arquivo | O que tem |
|---|---|
| [`docs/COMO_FOI_FEITO.md`](docs/COMO_FOI_FEITO.md) | **a história**, marco a marco, em linguagem simples: do jogo que parava no primeiro segundo até a partida inteira a 60 quadros por segundo |
| [`docs/METODO.md`](docs/METODO.md) | **o método**: as técnicas de engenharia já usadas e validadas que guiaram o trabalho, de onde cada uma vem e onde foi usada |
| [`docs/RECOMPILADOR.md`](docs/RECOMPILADOR.md) | cada mudança no recompilador, com o porquê e a medida |
| [`ESTADO.md`](ESTADO.md) | o diário técnico do projeto, marco a marco |
| [`docs/PLANO.md`](docs/PLANO.md) | o plano aprovado no primeiro dia |
| [`docs/INSTALADOS.md`](docs/INSTALADOS.md) | tudo o que foi instalado na máquina de desenvolvimento, e como remover |

## Como está montado

- `recomp/`: o [ps2-web-recomp](https://github.com/snuri00/ps2-web-recomp) (licença MIT, mantida em `recomp/LICENSE`), copiado do commit `ebf86d3` e com as correções para o PES.
- `config/`: o que é do PES 2012 e não é código do jogo: a correção de 60 Hz (`pes2012-patches.txt`) e os pontos de entrada de código que a análise estática não acha sozinha (`pes2012-entries.txt`), descobertos rodando o jogo até uma partida inteira.
- `scripts/`: preparar o jogo, servir no Windows, instalar e remover, e as ferramentas de teste (`rodar-teste.sh`, `explorar-de-estado.sh`).

**Para quem vai mexer no código:** ative o gancho que trava arquivo do jogo (`git config core.hooksPath .githooks`). O jeito de trabalhar deste projeto (editar no Windows e compilar num espelho dentro do Ubuntu) está no `scripts/espelhar-no-ubuntu.sh` e no `ESTADO.md`. As opções de diagnóstico (`?PS2_TIMING=1`, `?PS2_TRACE_FRAMES=1`, `?nowait` e outras) estão no `docs/RECOMPILADOR.md`.

## Licença

O código deste repositório está sob a licença MIT ([`LICENSE`](LICENSE)); o recompilador mantém a dele ([`recomp/LICENSE`](recomp/LICENSE), também MIT). Nenhuma das duas cobre o jogo, que é da Konami.
