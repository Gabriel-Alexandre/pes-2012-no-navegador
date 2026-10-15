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

## Regras do projeto

1. Nada do jogo no git, em nenhum commit.
2. O jogo roda só localmente. Não existe versão hospedada.
3. Toda instalação no computador entra em `docs/INSTALADOS.md` no mesmo passo em que acontece.
4. Commit e push a cada iteração.
