#!/usr/bin/env bash
# Prepara o PES 2012 a partir do SEU disco: confere a imagem, coloca as correções deste
# repositório no lugar e roda o recompilador (tradução para C++, exploração e as duas
# versões: a de navegador e a nativa).
#
# Uso, dentro do Ubuntu (WSL) ou de outro Linux, na pasta do repositório:
#   bash scripts/preparar-pes.sh /caminho/para/PES2012.iso
#   bash scripts/preparar-pes.sh /caminho/para/PES2012.iso --native-only   (só a versão nativa)
# Qualquer opção depois da imagem vai direto para o recomp/scripts/port.sh.
#
# Antes, uma vez: sudo bash scripts/instalar-ubuntu.sh
# A primeira execução baixa o Emscripten (~1 GB, em recomp/tools) e leva uns 20 minutos.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
R="$REPO/recomp"
JOGO="$R/games/pes2012"
MD5_TESTADO="c6a29549273f60475a6765791886eae6"   # SLES-55658, PAL europeia (espanhol, italiano, português, grego)

[ $# -ge 1 ] || { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
ISO="$1"; shift
[ -f "$ISO" ] || { echo "não achei a imagem: $ISO" >&2; exit 1; }
ISO="$(realpath "$ISO")"

case "${ISO,,}" in
  *.iso)
    echo "== conferindo a imagem (MD5 de 2,6 GB, leva uns segundos)"
    md5=$(md5sum "$ISO" | cut -d' ' -f1)
    if [ "$md5" = "$MD5_TESTADO" ]; then
      echo "ok: é a versão SLES-55658, a que este repositório testou"
    else
      echo "⚠️  MD5 $md5: não é a SLES-55658. Outra versão pode funcionar, mas as correções"
      echo "    de config/ foram feitas para aquela; o 60 Hz, por exemplo, só se aplica se a"
      echo "    instrução esperada estiver no mesmo endereço (o tradutor confere e avisa)."
    fi
    ;;
  *) echo "== imagem compactada: o port.sh extrai a .iso de dentro dela" ;;
esac

echo "== correções deste repositório em recomp/games/pes2012"
mkdir -p "$JOGO"
cp "$REPO/config/pes2012-patches.txt" "$JOGO/patches.txt"
# os pontos de entrada já descobertos, sem os comentários, somados aos que a máquina já tiver
touch "$JOGO/entries.txt"
grep -v '^#' "$REPO/config/pes2012-entries.txt" | grep -v '^$' | cat - "$JOGO/entries.txt" | awk '!visto[$0]++' > "$JOGO/entries.novo"
mv "$JOGO/entries.novo" "$JOGO/entries.txt"

echo "== recompilando (recomp/scripts/port.sh)"
cd "$R"
bash scripts/port.sh pes2012 "$ISO" --rounds 2 "$@"

echo
echo "Pronto. Para jogar:"
echo "  no Windows (recomendado, usa a placa de vídeo): powershell -ExecutionPolicy Bypass -File scripts\\servir-no-windows.ps1"
echo "  num Linux com WebGPU: python3 recomp/scripts/serve.py recomp/build/web-pes2012 recomp/games/pes2012/disc.iso"
echo "e abra http://localhost:8620 no Chrome."
