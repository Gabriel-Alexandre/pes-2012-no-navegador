#!/usr/bin/env bash
# Instala no Ubuntu (WSL) o que o recompilador precisa e registra cada pacote
# novo em docs/apt-instalados.txt, para remover depois com scripts/desinstalar-ubuntu.sh.
# Rodar uma vez, com sudo:
#   wsl -d Ubuntu-22.04 -- sudo bash /mnt/c/Users/Gabriel/Downloads/repositorios/pes-2012-no-navegador/scripts/instalar-ubuntu.sh
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$REPO/docs/apt-instalados.txt"
antes=$(mktemp)
dpkg-query -W -f='${Package}\n' | sort > "$antes"

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates gnupg wget lsb-release

# clang 19 com libc++: o recompilador exige <format> (clang 17+ ou GCC 13+),
# e o Ubuntu 22.04 só traz clang 14 e GCC 11.
codename=$(lsb_release -cs)
wget -qO /etc/apt/trusted.gpg.d/apt.llvm.org.asc https://apt.llvm.org/llvm-snapshot.gpg.key
echo "deb http://apt.llvm.org/$codename/ llvm-toolchain-$codename-19 main" > /etc/apt/sources.list.d/llvm-19.list
apt-get update
apt-get install -y clang-19 lld-19 libc++-19-dev libc++abi-19-dev

# CMake e Ninja (build), unzip (wgpu-native), p7zip (imagem do disco),
# SDL2 (janela do executor nativo), xz e python3 (scripts e Emscripten).
apt-get install -y cmake ninja-build unzip p7zip-full libsdl2-dev xz-utils python3 python3-venv

depois=$(mktemp)
dpkg-query -W -f='${Package}\n' | sort > "$depois"
{
  echo "# Pacotes que scripts/instalar-ubuntu.sh instalou em $(date -Iseconds)"
  echo "# Remover: wsl -d Ubuntu-22.04 -- sudo bash .../scripts/desinstalar-ubuntu.sh"
  comm -13 "$antes" "$depois"
} > "$LOG"
rm -f "$antes" "$depois"
echo "== pronto: $(grep -vc '^#' "$LOG") pacotes novos registrados em docs/apt-instalados.txt"
