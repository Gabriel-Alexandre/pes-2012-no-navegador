#!/usr/bin/env bash
# Roda o PES recompilado sem janela, com toques programados, e guarda as telas e o log.
# Uso (no Ubuntu):  bash rodar-teste.sh <nome> <quadros> [--press QUADRO:BOTAO ...]
#   ex.: bash rodar-teste.sh titulo 7200 --press 300:start --press 600:cross
# Saída: ~/pes-work/testes/<nome>/{telas,log.txt,memcard.ps2}
# Botões: start select cross circle square triangle up down left right l1 r1 l2 r2
set -euo pipefail
nome="$1"; quadros="$2"; shift 2
R="${PES_RECOMP:-$HOME/pes-work/recomp}"   # o espelho; PES_RECOMP aponta outro
D="$HOME/pes-work/testes/$nome"
rm -rf "$D"; mkdir -p "$D/telas"
PS2_GPU_LOW_POWER=1 "$R/build/native-pes2012/ps2run" "$R/games/pes2012/disc/SLES_556.58" \
  --disc "$R/games/pes2012/disc.iso" --memcard "$D/memcard.ps2" \
  --frames "$quadros" --frames-dir "$D/telas" --frame-every 150 "$@" > "$D/log.txt" 2>&1 || true
grep -E "halted|stopped" "$D/log.txt" | tail -2
echo "telas: $(ls "$D/telas" | wc -l) em $D/telas"
