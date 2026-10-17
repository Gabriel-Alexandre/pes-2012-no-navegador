#!/usr/bin/env bash
# Só para quem EDITA o código no Windows (quem só quer jogar usa scripts/preparar-pes.sh).
# Espelha o código de recomp/ para ~/pes-work/recomp, no disco do próprio Ubuntu, onde a
# compilação roda. Rodar antes de cada build:
#   wsl -d Ubuntu-22.04 -e bash /mnt/c/<caminho do repositório>/scripts/espelhar-no-ubuntu.sh
#
# Por que espelhar e não usar links: com build/ como link para outro disco, o CMake grava
# caminhos relativos a partir do link e o ninja, rodando na pasta real, não os acha
# ("manifest 'build.ninja' still dirty after 100 tries"). E compilar em /mnt/c é lento.
#
# As pastas de trabalho (build, generated, games, tools, third_party/wgpu-native) só
# existem no espelho e nunca são apagadas pela sincronização.
set -euo pipefail
ORIGEM="$(cd "$(dirname "$0")/.." && pwd)/recomp/"
DESTINO="$HOME/pes-work/recomp/"
mkdir -p "$DESTINO"
rsync -a --delete \
  --exclude /build --exclude /generated --exclude /games --exclude /tools \
  --exclude /third_party/wgpu-native --exclude /docs/media \
  "$ORIGEM" "$DESTINO"
# correções do executável (60 Hz) e pontos de entrada já descobertos, lidos pelo port.sh
JOGO="$DESTINO/games/pes2012"
mkdir -p "$JOGO"
cp "$(dirname "$ORIGEM")/config/pes2012-patches.txt" "$JOGO/patches.txt"
touch "$JOGO/entries.txt"
tr -d '' < "$(dirname "$ORIGEM")/config/pes2012-entries.txt" | grep -v '^#' | grep -v '^$' | cat - "$JOGO/entries.txt" | awk '!visto[$0]++' > "$JOGO/entries.novo"
mv "$JOGO/entries.novo" "$JOGO/entries.txt"
echo "== espelhado em $DESTINO"
