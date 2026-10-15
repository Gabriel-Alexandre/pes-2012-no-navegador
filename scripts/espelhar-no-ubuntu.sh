#!/usr/bin/env bash
# Espelha o código de recomp/ (editado no Windows) para ~/pes-work/recomp, no disco
# do próprio Ubuntu, onde a compilação roda. Rodar antes de cada build:
#   wsl -d Ubuntu-22.04 -e bash /mnt/c/Users/Gabriel/Downloads/repositorios/pes-2012-no-navegador/scripts/espelhar-no-ubuntu.sh
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
# correções do executável (60 Hz), lidas pelo port.sh e pelo explorar-de-estado.sh
mkdir -p "$DESTINO/games/pes2012"
cp "$(dirname "$ORIGEM")/config/pes2012-patches.txt" "$DESTINO/games/pes2012/patches.txt"
echo "== espelhado em $DESTINO"
