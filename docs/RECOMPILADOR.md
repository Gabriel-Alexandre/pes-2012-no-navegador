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
| 15/out/2026 | `runtime/src/kernel.cpp` (`RemoveIntcHandler`) | ao remover um tratador de interrupção, se ainda houver outro registrado na mesma causa, ela continua ligada | o reprodutor de vídeo do PES registra um tratador de vblank e, no fim do vídeo de abertura, chama `DisableIntc(2)` e o remove; o tratador do próprio jogo (o contador de quadros em `0x146660`, que o laço de espera em `0x13A068` consulta) ficava registrado e mudo, e a tela ficava preta para sempre. Com isso a **tela de título e o primeiro menu aparecem**. ⚠️ É um contorno validado pelo resultado, não pela documentação do kernel do PS2 |
| 15/out/2026 | `recomp/elf.cpp` | o tradutor só lê como código os **bytes do arquivo** de cada segmento executável; a parte zerada (`memsz` além do `filesz`) e os segmentos vazios ficam de fora | as vagas de overlay do PES são segmentos sem bytes; traduzidas como zeros, viravam um "escorregador" de `nop` que levava o `jal 0x0093EBA0` até `0x01DD3000`, o fim do programa |
| 15/out/2026 | `recomp/main.cpp`, `recomp/codegen.{hpp,cpp}` | opção `--overlays <pasta>`: lê as entradas **MWo3** (cabeçalho: assinatura, número, endereço de carga, fim do código, dados, área zerada, fim, nome em `0x20`; código a partir de `0x80`; a entrada inteira é carregada no endereço), traduz cada overlay com código **no endereço dele** e gera a tabela `kOverlays` com 8 palavras de assinatura por overlay | o PES 2012 carrega 30 overlays com código (de 67 entradas no `OVER.AFS`), vários na mesma vaga; o recompilador só conhecia módulos SNR2 |
| 15/out/2026 | `runtime/include/ps2/generated.hpp`, `runtime/src/dispatch.cpp` | `OverlayInfo` e `register_overlays`; quando o código não está no programa principal, o executor confere as assinaturas para saber **qual overlay está na memória agora** e chama a tradução dele; o que faltar vira `nome:endereço` no arquivo de faltas | é o que permite várias traduções no mesmo endereço |
| 15/out/2026 | `scripts/port.sh` | extrai o `OVER.AFS` e passa `--overlays` quando o disco tem; e diz `cannot load` em vez de "ran to the end" quando o executor nem liga | o "ran to the end" escondeu a falha de carga |
| 15/out/2026 | `runtime/src/system.cpp` (`load_elf`) | segmento **sem bytes no arquivo** que passa da RAM principal é ignorado, com aviso, em vez de recusar o executável inteiro | o `SLES_556.58` tem 70 segmentos (overlays da Konami) e o último fica em `0x03000000` (48 MB), `filesz 0`, `memsz 0x800`, sobra de um script de link de kit de desenvolvimento. O carregador do console só copia os bytes do arquivo. Sem isso: `cannot load` e o jogo não ligava |
| 15/out/2026 | `host/window.cpp` | se o SDL for anterior ao 2.26, `SDL_GetWindowSizeInPixels` vira `SDL_GetWindowSize` | o Ubuntu 22.04 traz o SDL 2.0.20, que não tem a função; a janela do executor nativo não compilava. Sem escala de tela alta, os dois dão o mesmo tamanho |
