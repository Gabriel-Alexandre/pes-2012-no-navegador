"""Separa as entradas MWo3 do OVER.AFS em arquivos, para análise (fora do git, em ~/pes-work).

Uso: python3 -I scripts/extrair-overlays.py ~/pes-work/analise/OVER.AFS ~/pes-work/analise/overlays
Cada entrada vira <indice>_id<id>_<endereco>.bin, com o cabeçalho de 16 bytes incluído,
e um indice.tsv com os campos do cabeçalho.
"""
import struct
import sys
from pathlib import Path

origem, destino = Path(sys.argv[1]), Path(sys.argv[2])
destino.mkdir(parents=True, exist_ok=True)
data = origem.read_bytes()
assert data[:4] == b"AFS\0", "não é AFS"
n = struct.unpack_from("<I", data, 4)[0]
linhas = ["indice\tid\tendereco\tcampo3\ttamanho\tarquivo"]
for i in range(n):
    off, size = struct.unpack_from("<II", data, 8 + i * 8)
    blob = data[off:off + size]
    magic, ident, addr, campo3 = struct.unpack_from("<4sIII", blob, 0)
    nome = f"{i:02d}_id{ident:02X}_{addr:08X}.bin"
    (destino / nome).write_bytes(blob)
    linhas.append(f"{i}\t0x{ident:02X}\t0x{addr:08X}\t0x{campo3:08X}\t{size}\t{nome}")
(destino / "indice.tsv").write_text("\n".join(linhas) + "\n")
print(f"{n} entradas em {destino}")
