# Serve a versão de navegador direto do Windows, para jogar no Chrome com a placa de vídeo.
#
# Por quê: servida de dentro do Ubuntu (WSL), cada leitura do disco atravessa o repasse de rede
# do WSL e levava ~310 ms (até 1 s) para ~250 KB; o jogo ficava parado esperando o disco.
#
# O que faz: acha a versão de navegador no Ubuntu (a que scripts/preparar-pes.sh gerou), copia
# ela e a imagem do disco para %USERPROFILE%\pes-work-windows (fora dos repositórios; a imagem
# só é copiada na primeira vez) e roda o recomp\scripts\serve.py com o Python do Windows, que
# só escuta no próprio computador. Depois é só abrir http://localhost:8620 no Chrome.
#
# Rodar:   powershell -ExecutionPolicy Bypass -File scripts\servir-no-windows.ps1
# Opções:  -Distro Ubuntu-22.04 (o nome do Ubuntu no WSL)  ·  -Recomp /home/voce/caminho/recomp
# Remover: apagar %USERPROFILE%\pes-work-windows (ver docs/INSTALADOS.md)
param(
    [string]$Distro = 'Ubuntu-22.04',
    [string]$Recomp = ''
)
$ErrorActionPreference = 'Stop'

if (-not $Recomp) {
    # o espelho de quem edita no Windows (~/pes-work) ou o repositório clonado dentro do Ubuntu
    $procura = 'for d in "$HOME/pes-work/recomp" "$HOME/pes-2012-no-navegador/recomp"; do if [ -d "$d/build/web-pes2012" ]; then echo "$d"; exit 0; fi; done'
    $Recomp = "$(wsl.exe -d $Distro -e sh -c $procura)".Trim()
}
if (-not $Recomp) {
    throw "Não achei a versão de navegador no Ubuntu '$Distro'. Rode antes scripts/preparar-pes.sh, ou passe -Recomp /caminho/para/recomp."
}
$wsl = "$(wsl.exe -d $Distro -e wslpath -w $Recomp)".Trim()
$dest = Join-Path $env:USERPROFILE 'pes-work-windows'
$web = Join-Path $dest 'web-pes2012'
New-Item -ItemType Directory -Force $web | Out-Null

Write-Host "== copiando a versão de navegador de $Recomp"
robocopy "$wsl\build\web-pes2012" $web ps2web.* boot.txt /NFL /NDL /NJH /NJS /NP | Out-Null

# estados salvos de teste (?state=nome.state), se existirem: só na máquina de quem desenvolve
$estados = "$(wsl.exe -d $Distro -e sh -c 'd="$HOME/pes-work/estados"; [ -d "$d" ] && echo "$d"')".Trim()
if ($estados) {
    robocopy "$(wsl.exe -d $Distro -e wslpath -w $estados)".Trim() $web *.state /NFL /NDL /NJH /NJS /NP | Out-Null
}

$iso = Join-Path $dest 'disc.iso'
if (-not (Test-Path $iso)) {
    Write-Host '== copiando a imagem do disco (2,6 GB, só na primeira vez)'
    # pelo próprio Ubuntu, porque games/pes2012/disc.iso costuma ser um link para a imagem
    $destinoLinux = "$(wsl.exe -d $Distro -e wslpath -u $iso)".Trim()
    wsl.exe -d $Distro -e cp -L "$Recomp/games/pes2012/disc.iso" $destinoLinux
    if (-not (Test-Path $iso)) { throw 'A cópia da imagem falhou.' }
}

Write-Host '== servindo em http://localhost:8620 (Ctrl+C para parar)'
python (Join-Path $PSScriptRoot '..\recomp\scripts\serve.py') $web $iso
