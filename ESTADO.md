# Estado

**Atualizado:** 15/out/2026.

| Marco | Estado |
|---|---|
| 0. Bancada | ✅ Windows (JDK 21, Ghidra 12.1.4 com o plugin do PS2, Node 24, REA 6.5.0 registrado no Claude Code) e Ubuntu (clang 19.1.7, 134 pacotes registrados, Emscripten 6.0.11, wgpu-native). Recompilador compilado no espelho `~/pes-work/recomp` (`eerecomp` e `vurecomp`). ⬜ O REA como ferramenta aparece só numa sessão nova do Claude Code |
| 1. A imagem | ✅ extraída, MD5 `c6a29549273f60475a6765791886eae6` confere, em `~/pes-work/games/pes2012/disc.iso` |
| 2. Primeira tradução | ✅ feita; ele decidiu seguir (15/out) e o suporte aos overlays `MWo3` foi construído |
| 3. Abrir o jogo | 🟡 **o jogo chega aos menus (15/out):** idioma, avisos do memory card, vídeo de abertura, **tela de título** ("PULSA UN BOTÓN") e a **escolha de dificuldade**. A tela preta depois do vídeo era o vblank desligado pelo reprodutor de vídeo (ver `docs/RECOMPILADOR.md`). Defeito gráfico: listras horizontais no fundo das caixas de menu |
| 4. A partida | 🟡 **o jogo entra na partida (15/out):** menu "Partido" → "Amistoso" → seleção (`select1.ovl`) → o `game.ovl` carrega → estádio Artemio Franchi com o painel de clima, túnel e **times perfilados no gramado**, em 3D. Foram 3 rodadas de exploração (`select1:6caf00`, `game:d28d00`, `2efd90`) e a 4ª rodou 9.000 quadros sem faltar código. Defeito: **rostos dos jogadores sem textura** (máscara bege). ✅ **O jogo anda (15/out):** a partir do estado do pontapé inicial, 100 s de partida sem faltar código, com relógio (3:16 → 13:01), placar, nomes, radar e replay. Foram precisas as sementes de chamadas diretas entre programa principal e overlays (o `game.ovl` atravessa as vagas de outros). ✅ **Partida inteira (15/out):** do pontapé inicial ao apito final, sem faltar código, com gol (Amistoso **AUT 0 × 1 AUT**, gol contra) e o jogo **gravando no memory card** ("Guardar datos", quadros ~19.500 a 20.400 a partir do estado do pontapé) |
| 5. Som e controle | ⬜ |
| 6. Navegador | 🟡 **roda no navegador (15/out):** `scripts/build_web.sh pes2012` gera `ps2web.wasm` (77 MB, 5 min 41 s); servido em `localhost:8620`, no Chromium do Windows usa a placa de vídeo (`GPU nvidia ampere`, WebGPU, isolamento de origem ativo) e chega à tela de idioma, **sem as listras** (eram só do desenho por software). ✅ **Na velocidade do PS2 (15/out):** **50 quadros por segundo** dentro da partida, com folga (processador principal 61% ocioso, VU 83%, GS 87%, placa de vídeo 22% ocupada). A lentidão medida antes não era do emulador: (1) pelo `localhost`, o Chrome tentava o IPv6 e **cada leitura do disco esperava ~300 ms** (corrigido no `serve.py`, e o servidor passou para o Windows com `scripts/servir-no-windows.ps1`); (2) o painel do navegador embutido, **escondido**, dava à página ~1 sinal de quadro por segundo, e o jogo espera cada quadro ser exibido. ⚠️ Os rodapés "idle" da página são **ociosidade**, não ocupação |
| 7. Publicação | ⬜ só se ele decidir |
| 8. Bomba Patch | ⬜ bônus |

## O que o disco já mostrou (Marco 1)

- `SYSTEM.CNF`: `BOOT2 = cdrom0:\SLES_556.58;1`, `VMODE = PAL`.
- **Não há módulo de rede no disco.** O risco que o plano inicial apontava (adaptador de rede) cai. Os suspeitos passam a ser os módulos USB (`USBD`, `USBKEYBD`, `USBPSPCM`), o áudio `CRI_ADXI` e o `CDVDSTM`.
- Os vídeos existem em versão `_N` e `_P` (60 e 50 Hz), e os textos e sons ficam em arquivos `.AFS` por idioma.
- **O executável `SLES_556.58` não tem símbolos** (`.symtab` vazia, seções sem nome, um segmento de código de 3,3 MB a partir de `0x00100000`). No Ghidra, os nomes vão depender de assinaturas do SDK do PS2.
- O áudio é o **middleware CRI ADX** compilado em **fev/2005** (ADXT 9.44, ADXF 7.30, ADXPS2 2.60): o motor do PES de PS2 vem dessa época.

## O que a primeira tradução mostrou (Marco 2, 15/out/2026)

Três tentativas, logs em `~/pes-work/logs/marco2-tentativa{1,2,3}.log`.

1. O executável virou **1.686 unidades de C++** (68 MB) e compilou inteiro (2 min 52 s, 12 núcleos).
2. Duas correções no recompilador (`docs/RECOMPILADOR.md`): o SDL antigo do Ubuntu e o **segmento vazio em `0x03000000`** que impedia o executável de carregar.
3. ✅ **O jogo liga:** reinicia o IOP com `IOPRP300.IMG`, carrega **os 12 módulos do disco sem nenhuma biblioteca faltando** (inclusive USB e CRI ADX), cria 11 threads e acha o memory card.
4. 🔴 **E para no primeiro código que o jogo carrega do disco.** O PES usa **overlays de código** num formato próprio da Konami, guardados no `OVER.AFS`:
   - `OVER.AFS` = arquivo AFS com **67 entradas**; cada uma começa com o cabeçalho **`MWo3`**, um número de overlay, o **endereço fixo** onde é carregada e o tamanho. Ex.: entrada 0 = overlay `0x1F`, carregada em `0x0093C800`.
   - Os endereços batem com as **regiões vazias** do executável (os 70 segmentos com `filesz 0`): são as "vagas" onde os overlays entram, e **várias overlays dividem a mesma vaga**.
   - Pela medida de densidade de instruções (`jr ra` e prólogos por KiB), **cerca de 35 das 67 entradas são código**; as outras são dados.
   - O ponto exato: em `0x002B59C8` o jogo faz `jal 0x0093EBA0`, dentro da vaga do overlay `0x1F`. O executor para com `missing code at 0x01DD3000 (ra 0x002B59D0)`. ⬜ A confirmar na próxima sessão por que o `pc` aparece como `0x01DD3000` (fim da imagem) e não `0x0093EBA0`.
5. O recompilador **não tem interpretador** do processador principal. Ele só suporta código carregado em execução no formato **SNR2** (SN Systems, o do GT4), que reconhece pelo cabeçalho na memória (`runtime/src/dispatch.cpp`, `instance_for`). `MWo3` não é SNR2.
6. ⚠️ O `port.sh` diz "ran to the end" mesmo quando o executor nem liga: **ler sempre o `games/pes2012/explore.log`**.

### O que falta construir (se ele decidir seguir)

Suporte a **overlays de endereço fixo** no recompilador:

1. Ler o `OVER.AFS`, separar as entradas `MWo3` que são código e confirmar o formato do cabeçalho (o 4º campo parece o tamanho; os bits `0x40` e `0xC0` ainda sem significado).
2. Traduzir cada overlay como um bloco de unidades **no endereço dela** (código absoluto, sem realocação).
3. No executor, quando o código cair numa vaga, descobrir **qual overlay está carregada agora** comparando palavras de assinatura na memória (o mesmo princípio dos `checks` do SNR2, sem o cabeçalho) e despachar para a tradução certa.
4. Rodar de novo e ver o próximo ponto de parada.

## O suporte aos overlays (15/out/2026, tentativas 4 a 8)

O que foi preciso, em ordem (detalhe em `docs/RECOMPILADOR.md`):

1. **Não traduzir zeros como código** (`elf.cpp`): as vagas vazias viravam um escorregador de `nop`.
2. **Ler e traduzir os 30 overlays com código** (`--overlays`), cada um no endereço dele, e **reconhecer na memória qual está carregado** (8 palavras de assinatura). Funcionou de primeira: a falta veio anotada como `memorycard:691ff0`.
3. **Sementes, para não achar uma função por rodada:** os `jal`/`j` dos overlays para o programa principal (83.289), os ponteiros nos dados do overlay, e os `jal`/`j`, palavras e pares `lui`+`addiu` do programa principal que caem num começo de função do overlay (1.260 entradas).

Resultado da 8ª tentativa: **uma rodada, 3.600 quadros, nenhum código faltando**, 12 capturas de tela.

| Quadros | Tela |
|---|---|
| 300 a 600 | escolha de idioma (com listras horizontais no fundo) |
| 900 a 1500 | avisos do memory card |
| 1800 a 2400 | vídeo de abertura |
| 2700 a 3600 | preta |

## Como compilar (o arranjo que funciona)

O código se edita em `recomp/` no Windows; a compilação roda no espelho do Ubuntu:

```bash
wsl -d Ubuntu-22.04 -e bash scripts/espelhar-no-ubuntu.sh      # sincroniza recomp/ -> ~/pes-work/recomp
wsl -d Ubuntu-22.04 -e bash --norc --noprofile -c 'cd ~/pes-work/recomp && bash scripts/port.sh pes2012 games/pes2012/disc.iso --native-only'
```

⚠️ Use `bash --norc --noprofile`: o `.bashrc` dele roda `sudo service docker start`, que trava esperando senha.
⚠️ **Não volte a usar links** para `build/`: o CMake grava caminhos relativos ao link e o ninja entra em laço (`build.ninja still dirty after 100 tries`).

## Próximo passo

1. ~~A tela preta depois do vídeo~~ ✅ resolvida (vblank).
2. ~~Avançar pelos menus até uma partida~~ ✅ chega aos times perfilados. Caminho de toques: Start em 300; ✕ em 450, 600, 750, 900, 1050, 1200, 1500; Start em 3000 e 3600; ✕ a cada 150 quadros a partir de 3900.
3. ~~As listras horizontais no fundo das caixas de menu~~ ✅ só acontecem no desenho por software; com WebGPU saem limpas.
3. ~~Desempenho no navegador~~ ✅ 50 quadros por segundo na partida (ver Marco 6).
4. 🔧 **Primeiro teste dele (15/out): "50 fps, mas a imagem muito travada".** O rodapé mostrava 50 fps com 50 na tela e muita folga: não era desempenho. O monitor dele é de **120 Hz**, e 50 quadros por segundo se alternam entre 2 e 3 atualizações da tela (17 e 25 ms), o que dá o engasgo, ainda mais com a câmera do futebol andando. **Correção: o jogo passa a iniciar em 60 Hz** (`config/pes2012-patches.txt`, uma instrução em `0x001203CC`); a 60 por segundo cada quadro fica sempre 2 atualizações. O jogo tem o caminho de 60 Hz (vídeos `_N`, `bootset.ovl`), mas nenhuma opção de menu chega nele ("Pantalla" só ajusta a posição). Conferido: modo NTSC (`SetGsCrt mode 2`), vídeos `WEPES_N` e `PES2012N`, imagem certa. O vídeo de abertura é longo de fábrica (~2,5 min) e se pula com Start ou ✕. **Navegador em 60 Hz:** 59,8 quadros por segundo, com folga (emulador 80% ocioso, GPU 25%).
   ✅ **Partida inteira em 60 Hz no nativo (15/out):** 48.000 quadros desde a abertura, sem faltar código, em NTSC, até gravar a repetição no memory card (Amistoso AUT 0 × 1 AUT).
5. 🔧 **Segundo teste dele no Chrome (15/out):** menus bons (seleciona, configura, inicia a partida). Defeitos: (a) **os primeiros vídeos depois do logo da Konami travam muito**; (b) **a entrada dos jogadores no campo trava**; (c) **na partida a imagem fica quebrada**: no print da apresentação dos jogadores, os modelos 3D saem **pretos** (silhuetas), só os textos, escudos e números aparecem. No desenho por software do nativo a mesma cena sai certa, então o defeito é do caminho WebGPU.
   **Investigação (pausada a pedido dele, 15/out à noite):**
   - **Bancada nova sem senha:** o Vulkan por software do Mesa (lavapipe) foi baixado com `apt-get download` e extraído em `~/pes-work/vulkan-local/` (sem instalar no sistema; registrado em `docs/INSTALADOS.md`). Com `. ~/pes-work/vulkan-local/env.sh` e `PS2_GPU_FALLBACK=1`, o executor nativo ganha um adaptador WebGPU (`llvmpipe`) e roda o mesmo caminho de desenho do navegador.
   - **Medido:** `PS2_GS=both PS2_GS_COMPARE=show` (WebGPU espelhando o software) dá **0 pixels diferentes** nos menus e na partida. Com `PS2_GS=gpu` (WebGPU sozinho, o modo do navegador), carregando `pontape.state`, o quadro sai **inteiro zerado** (nem o placar). O WebGPU sozinho desde o começo do jogo desenha os menus.
   - **O que distingue os dois modos** (`runtime/src/gs/gs.cpp`): no modo sozinho, os envios de imagem, as cópias dentro da memória de vídeo (`trx dir 2`), as leituras de volta (`trx dir 1`, `download_source`) e a CLUT só acontecem na placa; a memória de vídeo da CPU fica velha. Num traço de 30 quadros a partir do estado foram 1.034 transferências, **todas de envio** (`trx dir 0`).
   - **Próximo passo:** descobrir por que o quadro do modo sozinho sai zerado a partir do estado (comparar a memória de vídeo da placa com a do software depois de `write_state` e depois do primeiro quadro) e conferir se é o mesmo defeito que deixa o 3D preto no Chrome. A rodada `gpu-caminho` (do começo até os perfilados, só WebGPU, salvando `~/pes-work/estados/gpu-perfilados.state` no quadro 8.700) foi **interrompida no quadro 1.200**: o lavapipe faz ~300 quadros por minuto, ~35 min até a cena.
   - **As travadas (vídeos depois do logo e entrada dos jogadores) ainda não foram olhadas.** Para medir, o painel do navegador embutido precisa estar visível; escondido, ele segura os quadros (o rodapé mostrou "5 on screen").
5. ⬜ A próxima versão web já leva a opção `?nowait` no `shell.html` (hoje aplicada à mão na cópia servida).
4. Ele pode testar já na janela nativa (comando no README; por software dentro do WSL, então lenta).

## Como testar sem janela

**Explorar a partir de um estado salvo** (para não refazer os ~10 min de menus e pré-partida a cada rodada): `scripts/explorar-de-estado.sh <estado> <quadro final> <rodadas> [--press ...]`. O estado guarda a contagem de quadros, então o quadro final e os toques são absolutos. Para salvar: `rodar-teste.sh` com `--save-state QUADRO:caminho`. ⚠️ O limite de quadros precisa ser **maior** que o quadro do salvamento: no mesmo quadro, o executor para antes de salvar. Estado do pontapé inicial: `~/pes-work/estados/pontape.state` (quadro 12.900).

`scripts/rodar-teste.sh <nome> <quadros> [--press QUADRO:BOTAO ...] [--trace-syscalls] [--trace-io]` roda o jogo escondido e guarda as telas (uma a cada 150 quadros) e o log em `~/pes-work/testes/<nome>/`. Exemplo que chega à escolha de dificuldade: `--press 300:start` e ✕ em 450, 600, 750, 900, 1050, 1200 e 1500, depois Start a partir de 3000.
