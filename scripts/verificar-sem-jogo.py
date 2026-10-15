"""Trava o commit se qualquer arquivo do jogo tentar entrar no git.

Roda sozinho pelo gancho .githooks/pre-commit e pode rodar à mão:
    python scripts/verificar-sem-jogo.py           (arquivos preparados para o commit)
    python scripts/verificar-sem-jogo.py --tudo    (tudo o que o git rastreia)

Bloqueia:
- imagem de disco e arquivo compactado (.iso .7z .zip .rar .chd .cso .bin .img .mdf)
- executável e módulo do PS2 (.elf .irx), e qualquer arquivo que comece com o
  cabeçalho ELF de MIPS (o executável do jogo pode vir sem extensão: SLES_556.58)
- vídeo, áudio e textura extraídos do disco (.pss .vag .vgs .adx .tm2)
- tudo dentro de games/, generated/, build/ e tools/ do recompilador
- qualquer arquivo acima de 5 MB
"""
import subprocess
import sys
from pathlib import Path

EXTENSOES = {
    ".iso", ".7z", ".zip", ".rar", ".chd", ".cso", ".bin", ".img", ".mdf",
    ".elf", ".irx", ".pss", ".vag", ".vgs", ".adx", ".tm2",
}
PASTAS = ("recomp/games/", "recomp/generated/", "recomp/build/", "recomp/tools/", "work/")
LIMITE = 5 * 1024 * 1024
ELF_MIPS = 8  # e_machine do MIPS


def arquivos(tudo: bool) -> list[str]:
    cmd = ["git", "ls-files"] if tudo else ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"]
    saida = subprocess.run(cmd, capture_output=True, text=True, check=True).stdout
    return [linha for linha in saida.splitlines() if linha]


def problema(caminho: str) -> str | None:
    p = Path(caminho)
    if any(caminho.startswith(pasta) for pasta in PASTAS):
        return "pasta de trabalho do jogo"
    if p.suffix.lower() in EXTENSOES:
        return f"extensão {p.suffix}"
    if not p.is_file():
        return None
    if p.stat().st_size > LIMITE:
        return f"{p.stat().st_size / 1024 / 1024:.1f} MB"
    with p.open("rb") as f:
        cabecalho = f.read(20)
    if cabecalho[:4] == b"\x7fELF" and len(cabecalho) >= 20 and cabecalho[18] == ELF_MIPS:
        return "executável MIPS (PS2)"
    return None


def main() -> int:
    achados = [(c, motivo) for c in arquivos("--tudo" in sys.argv) if (motivo := problema(c))]
    if not achados:
        print("verificar-sem-jogo: nenhum arquivo do jogo")
        return 0
    print("verificar-sem-jogo: COMMIT BLOQUEADO. Arquivos que parecem do jogo:")
    for caminho, motivo in achados:
        print(f"  {caminho}  ({motivo})")
    return 1


if __name__ == "__main__":
    sys.exit(main())
