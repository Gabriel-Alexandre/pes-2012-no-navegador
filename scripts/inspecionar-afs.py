"""Lista as entradas de um .AFS e mede quanto cada uma parece código MIPS.

Uso: python3 -I scripts/inspecionar-afs.py ~/pes-work/analise/OVER.AFS
Heurística: conta 'jr ra' (0x03E00008) e prólogos 'addiu sp,sp,-N' (0x27BDxxxx com N negativo)
por KiB. Código MIPS compilado tem dezenas por KiB; dados quase nunca.
"""
import struct
import sys

data = open(sys.argv[1], "rb").read()
assert data[:4] == b"AFS\0", "não é AFS"
n = struct.unpack_from("<I", data, 4)[0]
print(f"{n} entradas")
for i in range(n):
    off, size = struct.unpack_from("<II", data, 8 + i * 8)
    blob = data[off:off + size]
    words = struct.unpack_from(f"<{len(blob) // 4}I", blob)
    jr = sum(1 for w in words if w == 0x03E00008)
    pro = sum(1 for w in words if (w >> 16) == 0x27BD and (w & 0x8000))
    kib = max(size / 1024, 1)
    head = blob[:16].hex(" ")
    print(f"{i:3d} off 0x{off:08X} {size:9d} B  jr/KiB {jr / kib:5.1f}  prologo/KiB {pro / kib:5.1f}  {head}")
