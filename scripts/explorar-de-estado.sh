#!/usr/bin/env bash
# Exploração a partir de um estado salvo: carrega o estado, roda, anota o código que faltou,
# traduz de novo, recompila e repete. Poupa os minutos de menus e pré-partida que o port.sh
# refaz a cada rodada.
# Uso (no Ubuntu):  bash explorar-de-estado.sh <estado> <quadro final> <rodadas> [--press QUADRO:BOTAO ...]
#   O estado guarda a contagem de quadros: o quadro final e os toques são ABSOLUTOS
#   (um estado salvo no quadro 12900 com "16000" roda 3.100 quadros).
# Saída: ~/pes-work/testes/estado-<nome do estado>/rodada-N/{telas,log.txt}
set -euo pipefail
estado="$1"; quadros="$2"; rodadas="$3"; shift 3
R="$HOME/pes-work/recomp"
G="$R/games/pes2012"
D="$HOME/pes-work/testes/estado-$(basename "$estado" .state)"
mkdir -p "$D"
for ((n = 1; n <= rodadas; n++)); do
  out="$D/rodada-$n"; rm -rf "$out"; mkdir -p "$out/telas"
  rm -f "$G/misses.txt"
  PS2_GPU_LOW_POWER=1 "$R/build/native-pes2012/ps2run" "$G/disc/SLES_556.58" --disc "$G/disc.iso" \
    --memcard "$out/memcard.ps2" --load-state "$estado" --misses "$G/misses.txt" \
    --frames "$quadros" --frames-dir "$out/telas" --frame-every 150 "$@" > "$out/log.txt" 2>&1 || true
  motivo=$(sed -n 's/^\[ee\] halted: //p' "$out/log.txt" | head -1)
  novos=$(python3 -I - "$G/entries.txt" "$G/misses.txt" <<'EOF'
import os, sys
entries, misses = sys.argv[1], sys.argv[2]
def token(t):
    name, _, at = t.rpartition(':')
    return (name + ':' if name else '') + '%x' % int(at, 16)
known = {token(t) for t in open(entries).read().split()}
found = [token(t) for t in open(misses).read().split()] if os.path.exists(misses) else []
new = sorted({t for t in found if t not in known})
with open(entries, 'a') as out:
    for t in new:
        out.write(t + '\n')
print(len(new))
EOF
)
  echo "rodada $n: ${motivo:-sem motivo registrado}, $novos entradas novas, $(ls "$out/telas" | wc -l) telas"
  [ "$novos" -gt 0 ] || break
  "$R/build/tools/eerecomp" "$G/disc/SLES_556.58" --entries "$G/entries.txt" --overlays "$G/overlays" --patches "$G/patches.txt" --out "$R/generated/pes2012" | tail -1
  ninja -C "$R/build/native-pes2012" ps2run > "$out/ninja.log" 2>&1 || { tail -20 "$out/ninja.log"; exit 1; }
done
