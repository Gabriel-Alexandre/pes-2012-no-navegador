#!/usr/bin/env bash
# Desfaz scripts/instalar-ubuntu.sh: remove os pacotes registrados, o repositório
# do LLVM e a pasta de trabalho ~/pes-work (build, código gerado, Emscripten, imagem).
# Rodar com sudo:
#   wsl -d Ubuntu-22.04 -- sudo bash /mnt/c/Users/Gabriel/Downloads/repositorios/pes-2012-no-navegador/scripts/desinstalar-ubuntu.sh
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$REPO/docs/apt-instalados.txt"
if [ -f "$LOG" ]; then
  pacotes=$(grep -v '^#' "$LOG" | tr '\n' ' ')
  [ -n "$pacotes" ] && apt-get remove -y --purge $pacotes
  apt-get autoremove -y
fi
rm -f /etc/apt/sources.list.d/llvm-19.list /etc/apt/trusted.gpg.d/apt.llvm.org.asc
apt-get update
dono=${SUDO_USER:-$(id -un)}
rm -rf "/home/$dono/pes-work"
echo "== Ubuntu limpo. Para devolver o espaço ao Windows, veja docs/INSTALADOS.md (compactar o disco do WSL)."
