# Serve a versão de navegador direto do Windows.
#
# Por quê: servida de dentro do Ubuntu (WSL), cada leitura do disco atravessa o repasse de rede
# do WSL e levava ~310 ms (até 1 s) para ~250 KB; o jogo ficava parado esperando o disco.
#
# O que faz: copia a versão de navegador e a imagem do disco do Ubuntu para C:\Users\Gabriel\pes-work-windows
# (fora dos repositórios; a imagem só é copiada se ainda não estiver lá) e roda o mesmo serve.py
# com o Python do Windows. Depois é só abrir http://localhost:8620 no Chrome.
#
# Rodar:  powershell -File scripts\servir-no-windows.ps1
# Remover: apagar C:\Users\Gabriel\pes-work-windows (ver docs/INSTALADOS.md)

$ErrorActionPreference = 'Stop'
$wsl = '\\wsl.localhost\Ubuntu-22.04\home\gabriel\pes-work\recomp'
$dest = Join-Path $env:USERPROFILE 'pes-work-windows'
$web = Join-Path $dest 'web-pes2012'
New-Item -ItemType Directory -Force $web | Out-Null

Write-Host '== copiando a versão de navegador'
robocopy "$wsl\build\web-pes2012" $web ps2web.* boot.txt /NFL /NDL /NJH /NJS /NP | Out-Null

# estados salvos de teste (?state=nome.state): pontapé, antes do túnel e partida em 60 Hz
$estados = '\\wsl.localhost\Ubuntu-22.04\home\gabriel\pes-work\estados'
if (Test-Path $estados) { robocopy $estados $web *.state /NFL /NDL /NJH /NJS /NP | Out-Null }

$iso = Join-Path $dest 'disc.iso'
if (-not (Test-Path $iso)) {
    Write-Host '== copiando a imagem do disco (2,6 GB, só na primeira vez)'
    Copy-Item "$wsl\games\pes2012\disc.iso" $iso
}

Write-Host '== servindo em http://localhost:8620 (Ctrl+C para parar)'
python (Join-Path $PSScriptRoot '..\recomp\scripts\serve.py') $web $iso
