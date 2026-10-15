# O recompilador

## Origem

| | |
|---|---|
| Projeto | [snuri00/ps2-web-recomp](https://github.com/snuri00/ps2-web-recomp) |
| Licença | MIT (`recomp/LICENSE`); `runtime/src/ipu/tables.hpp` mantém o aviso BSD-2 do Play! |
| Commit copiado | `ebf86d3b8fa915d38cb070bfd70b6b41669816d5` (15/out/2026, 08:23 +02:00) |
| Como entrou | `git clone --depth 1` e cópia sem o `.git`, porque o GitHub não deixa fork privado de repositório público |

## O que ele já provou (segundo o README dele)

- **Gran Turismo 4** e **God of War II**, do boot ao jogo, a 50 e 60 fps no Chrome.
- O God of War II não precisou de código específico do jogo. As falhas que ele expôs foram corrigidas de forma genérica.
- Outros jogos "muito provavelmente param" em chamada de sistema, biblioteca do processador de entrada e saída (IOP) ou recurso gráfico ainda não implementados.

## Requisitos que ele impõe

- Compilador com `<format>`: clang 17+ com libc++, ou GCC 13+ (`scripts/cxx.sh`). O Ubuntu 22.04 traz clang 14 e GCC 11, então instalamos o clang 19 (`scripts/instalar-ubuntu.sh`).
- CMake 3.20+, Ninja, Python 3, unzip e 7-Zip.
- O `setup.sh` dele baixa sozinho o **Emscripten 6.0.11** para `recomp/tools/emsdk` e o **wgpu-native v29.0.1.1** para `recomp/third_party/wgpu-native`. Os dois ficam no Ubuntu e estão registrados em `INSTALADOS.md`.
- O navegador precisa servir a página com `Cross-Origin-Opener-Policy` e `Cross-Origin-Embedder-Policy` (`scripts/serve.py` já faz).

## O que mudamos nele

| Data | Arquivo | Mudança | Por quê |
|---|---|---|---|
| | | (nada ainda) | |
