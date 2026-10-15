# Estado

**Atualizado:** 15/out/2026.

| Marco | Estado |
|---|---|
| 0. Bancada | ✅ Windows (JDK 21, Ghidra 12.1.4 com o plugin do PS2, Node 24, REA 6.5.0 registrado no Claude Code) e Ubuntu (clang 19.1.7, 134 pacotes registrados, Emscripten 6.0.11, wgpu-native). Recompilador compilado no espelho `~/pes-work/recomp` (`eerecomp` e `vurecomp`). ⬜ O REA como ferramenta aparece só numa sessão nova do Claude Code |
| 1. A imagem | ✅ extraída, MD5 `c6a29549273f60475a6765791886eae6` confere, em `~/pes-work/games/pes2012/disc.iso` |
| 2. Primeira tradução | ⬜ |
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

## Como compilar (o arranjo que funciona)

O código se edita em `recomp/` no Windows; a compilação roda no espelho do Ubuntu:

```bash
wsl -d Ubuntu-22.04 -e bash scripts/espelhar-no-ubuntu.sh      # sincroniza recomp/ -> ~/pes-work/recomp
wsl -d Ubuntu-22.04 -e bash --norc --noprofile -c 'cd ~/pes-work/recomp && bash scripts/port.sh pes2012 games/pes2012/disc.iso --native-only'
```

⚠️ Use `bash --norc --noprofile`: o `.bashrc` dele roda `sudo service docker start`, que trava esperando senha.
⚠️ **Não volte a usar links** para `build/`: o CMake grava caminhos relativos ao link e o ninja entra em laço (`build.ninja still dirty after 100 tries`).

## Próximo passo

Marco 2: a primeira tradução (`port.sh ... --native-only`), com log em `~/pes-work/logs/`.
