# Estado

**Atualizado:** 15/out/2026.

| Marco | Estado |
|---|---|
| 0. Bancada | ✅ Windows (JDK 21, Ghidra 12.1.4 com o plugin do PS2, Node 24, REA 6.5.0 registrado no Claude Code) e Ubuntu (clang 19.1.7, 134 pacotes registrados, Emscripten 6.0.11, wgpu-native). Recompilador compilado no espelho `~/pes-work/recomp` (`eerecomp` e `vurecomp`). ⬜ O REA como ferramenta aparece só numa sessão nova do Claude Code |
| 1. A imagem | ✅ extraída, MD5 `c6a29549273f60475a6765791886eae6` confere, em `~/pes-work/games/pes2012/disc.iso` |
| 2. Primeira tradução | 🟡 **feita, esperando a decisão dele** (ver "O que a primeira tradução mostrou") |
| 3. Abrir o jogo | ⬜ |
| 4. A partida | ⬜ |
| 5. Som e controle | ⬜ |
| 6. Navegador | ⬜ |
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

## Como compilar (o arranjo que funciona)

O código se edita em `recomp/` no Windows; a compilação roda no espelho do Ubuntu:

```bash
wsl -d Ubuntu-22.04 -e bash scripts/espelhar-no-ubuntu.sh      # sincroniza recomp/ -> ~/pes-work/recomp
wsl -d Ubuntu-22.04 -e bash --norc --noprofile -c 'cd ~/pes-work/recomp && bash scripts/port.sh pes2012 games/pes2012/disc.iso --native-only'
```

⚠️ Use `bash --norc --noprofile`: o `.bashrc` dele roda `sudo service docker start`, que trava esperando senha.
⚠️ **Não volte a usar links** para `build/`: o CMake grava caminhos relativos ao link e o ninja entra em laço (`build.ninja still dirty after 100 tries`).

## Próximo passo

🔴 **Decisão dele:** seguir para o suporte a overlays `MWo3` (seção acima) ou parar aqui. Se seguir: **sessão nova**, começando por este arquivo; o REA já aparece como ferramenta numa sessão nova.
