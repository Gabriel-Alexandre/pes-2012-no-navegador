# Desfaz, no Windows, tudo o que docs/INSTALADOS.md registra.
# O Ubuntu se limpa com scripts/desinstalar-ubuntu.sh (veja docs/INSTALADOS.md).
# Rodar: powershell -File scripts\desinstalar.ps1

$ErrorActionPreference = 'Continue'

Write-Host '== REA: registro no Claude Code e skill'
$claude = Join-Path $env:USERPROFILE '.claude.json'
if (Test-Path $claude) {
    python -c "import json,os;p=os.path.expanduser('~/.claude.json');d=json.load(open(p,encoding='utf-8'));d.get('mcpServers',{}).pop('rea',None);json.dump(d,open(p,'w',encoding='utf-8'),indent=2,ensure_ascii=False);print('chave rea removida')"
}
$skill = Join-Path $env:USERPROFILE '.claude\skills\reverse-engineer-anything'
if (Test-Path $skill) { Remove-Item -Recurse -Force $skill -Confirm:$false; Write-Host 'skill removida' }

Write-Host '== scoop: Ghidra (com o plugin do PS2), JDK 21 e Node 24'
scoop uninstall ghidra temurin21-jdk nodejs-lts
scoop bucket rm java

Write-Host '== pasta servida pelo Windows (versão de navegador e imagem do disco)'
$servida = Join-Path $env:USERPROFILE 'pes-work-windows'
if (Test-Path $servida) { Remove-Item -Recurse -Force $servida -Confirm:$false; Write-Host 'pasta removida' }

Write-Host '== variável GHIDRA_INSTALL_DIR'
[Environment]::SetEnvironmentVariable('GHIDRA_INSTALL_DIR', $null, 'User')

Write-Host '== pronto. Falta o Ubuntu: scripts/desinstalar-ubuntu.sh, e devolver o espaço (docs/INSTALADOS.md).'
