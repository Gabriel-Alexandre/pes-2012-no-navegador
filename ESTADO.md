# Estado

**Atualizado:** 15/out/2026.

| Marco | Estado |
|---|---|
| 0. Bancada | 🟡 Windows pronto (JDK 21, Ghidra 12.1.4 com o plugin do PS2, Node 24, REA 6.5.0 registrado no Claude Code). ⬜ Falta o Ubuntu: `scripts/instalar-ubuntu.sh` pede a senha dele; depois, compilar o recompilador |
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

## Próximo passo

1. Ele roda a linha de `scripts/instalar-ubuntu.sh` com a senha (terminal aberto na sessão).
2. Ligar `recomp/{games,generated,build,tools,third_party/wgpu-native}` a `~/pes-work` e rodar `recomp/scripts/setup.sh` no Ubuntu.
3. Reabrir a sessão do Claude Code para o REA aparecer, conferir `rea doctor` com o plugin do PS2.
4. Marco 2: `scripts/port.sh pes2012 ~/pes-work/games/pes2012/disc.iso --native-only` primeiro, para ler a lista do que falta.
