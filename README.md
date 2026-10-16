# PES 2012 no navegador

Projeto pessoal: rodar o **PES 2012 de PlayStation 2** dentro do navegador (Chrome, WebGPU), por **recompilação estática**: o código do processador do PS2 é traduzido para C++ e compilado para WebAssembly, e o resto do console é reimplementado em volta dele.

> 🔴 **Este repositório não tem nenhum arquivo do jogo, e nunca vai ter.** A imagem do disco, o executável, o C++ e o WebAssembly gerados a partir dela ficam só nesta máquina, fora do git. O gancho `.githooks/pre-commit` roda `scripts/verificar-sem-jogo.py` e trava o commit se algo do jogo tentar entrar.

## Por onde começar

| Arquivo | O que tem |
|---|---|
| [`ESTADO.md`](ESTADO.md) | **onde o projeto está agora**, marco a marco, e o próximo passo |
| [`docs/PLANO.md`](docs/PLANO.md) | o plano, os marcos e os pontos de decisão |
| [`docs/INSTALADOS.md`](docs/INSTALADOS.md) | **tudo o que foi instalado no computador**, onde e como remover |
| [`docs/RECOMPILADOR.md`](docs/RECOMPILADOR.md) | de onde veio o recompilador e o que mudamos nele |

## Como está montado

- `recomp/`: o [ps2-web-recomp](https://github.com/snuri00/ps2-web-recomp) (licença MIT, mantida em `recomp/LICENSE`), copiado para dentro deste repositório. As nossas correções para o PES vão aqui e ficam registradas em `docs/RECOMPILADOR.md`.
- O código fica no Windows (`Downloads/repositorios/pes-2012-no-navegador`). **A compilação roda no Ubuntu (WSL)**, que é onde o recompilador foi testado, numa **cópia espelhada** em `~/pes-work/recomp`: `scripts/espelhar-no-ubuntu.sh` sincroniza antes de cada build. As pastas pesadas (`games/` com a imagem, `generated/`, `build/`, `tools/` com o Emscripten, `third_party/wgpu-native`) só existem no espelho.
- `scripts/`: instalação, remoção e o verificador de que nada do jogo entra no git.

## Como testar nesta máquina

Janela nativa (o Windows 11 abre a janela do Ubuntu sozinho). ⚠️ **Dentro do Ubuntu do WSL não há placa de vídeo para o WebGPU** (`[gpu] no adapter`): a janela desenha por software e fica lenta. Serve para conferir se o jogo anda; para jogar, o caminho é o navegador no Windows, que usa a placa de vídeo:

```bash
wsl -d Ubuntu-22.04 -e bash --norc --noprofile -c 'cd ~/pes-work/recomp && build/native-pes2012/ps2run games/pes2012/disc/SLES_556.58 --disc games/pes2012/disc.iso --window'
```

**No navegador (o jeito de jogar).** Servir pelo Windows, não pelo Ubuntu: pelo repasse de rede do WSL cada leitura do disco ficava lenta. O script copia a versão de navegador e a imagem para `C:\Users\Gabriel\pes-work-windows` e sobe o servidor:

```bash
powershell -ExecutionPolicy Bypass -File C:\Users\Gabriel\Downloads\repositorios\pes-2012-no-navegador\scripts\servir-no-windows.ps1
```

Depois, abrir `http://localhost:8620` no **Chrome do Windows**, com a aba **visível**, e clicar em **Start**. Medido em 15/out: **50 quadros por segundo** (a velocidade do PS2 em PAL) na partida, com folga de mais da metade do processador.

Opções de diagnóstico no endereço: `?nowait` (não espera cada quadro ser exibido; serve para medir com a aba escondida), `?state=partida60.state` (partida rolando, 60 Hz), `?state=antes-tunel.state` (antes da entrada dos jogadores) ou `?state=pontape.state` (pontapé, 50 Hz), se o arquivo estiver na pasta servida; `?press=QUADRO:BOTAO,...` (toques programados); e qualquer `?PS2_...=valor` vira variável do executor (por exemplo `?PS2_TIMING=1`, que escreve no console onde vai o tempo).

| Tecla | PS2 |
|---|---|
| Setas | direcional |
| Z / X / A / S | ✕ / ◯ / ▢ / △ |
| Q / W · 1 / 2 | L1 / R1 · L2 / R2 |
| Enter / Backspace | Start / Select |
| I J K L (navegador) | analógico esquerdo |
| F11 (janela) · F (navegador) | tela cheia |

## Regras do projeto

1. Nada do jogo no git, em nenhum commit.
2. O jogo roda só localmente. Não existe versão hospedada.
3. Toda instalação no computador entra em `docs/INSTALADOS.md` no mesmo passo em que acontece.
4. Commit e push a cada iteração.
