# O que este projeto instalou no computador

Registro feito **no mesmo passo** de cada instalação, para remover tudo de uma vez quando o projeto acabar.

**Remover tudo:** `powershell -File scripts\desinstalar.ps1` (Windows) e `wsl -d Ubuntu-22.04 -- sudo bash /mnt/c/Users/Gabriel/Downloads/repositorios/pes-2012-no-navegador/scripts/desinstalar-ubuntu.sh` (Ubuntu). Depois, devolver o espaço do disco do Ubuntu ao Windows (último bloco).

## Windows

| Data | O quê | Onde | Tamanho | Como remover |
|---|---|---|---|---|
| 15/out/2026 | bucket `java` do scoop | `~\scoop\buckets\java` | catálogo | `scoop bucket rm java` |
| 15/out/2026 | **JDK 21** (Temurin 21.0.12) | `~\scoop\apps\temurin21-jdk` | 328 MB | `scoop uninstall temurin21-jdk` |
| 15/out/2026 | **Ghidra 12.1.4** | `~\scoop\apps\ghidra` | 864 MB | `scoop uninstall ghidra` |
| 15/out/2026 | plugin **ghidra-emotionengine-reloaded v2.1.38** (processador do PS2) | `~\scoop\apps\ghidra\current\Ghidra\Extensions\ghidra-emotionengine-reloaded` | 1 MB | sai junto com o Ghidra |
| 15/out/2026 | **Node 24.22** (só para o REA; o Node 22.18 do sistema não foi tocado) | `~\scoop\apps\nodejs-lts` | 102 MB | `scoop uninstall nodejs-lts` |
| 15/out/2026 | **REA 6.5.0** (pacote `rea-agents`, roda por `npx`) | cache do npm do Node do scoop | | sai junto com o Node do scoop |
| 15/out/2026 | pasta servida pelo Windows: a versão de navegador (~100 MB), a **imagem do disco (2,6 GB)** e o estado do pontapé inicial (42 MB), criada por `scripts/servir-no-windows.ps1` | `C:\Users\Gabriel\pes-work-windows` | apagar a pasta (o `desinstalar.ps1` faz) |
| 15/out/2026 | registro do REA no Claude Code | `~\.claude.json`, chave `mcpServers.rea` | | apagar a chave `rea` (backup do arquivo antes do REA: `~\.claude.json.rea.backup`) |
| 15/out/2026 | skill do REA no Claude Code | `~\.claude\skills\reverse-engineer-anything` | | apagar a pasta |

### Variáveis de ambiente do usuário

| Variável | Valor | Quem criou | Como remover |
|---|---|---|---|
| `GHIDRA_INSTALL_DIR` | `~\scoop\apps\ghidra\current` | este projeto (para o REA achar o Ghidra) | `[Environment]::SetEnvironmentVariable('GHIDRA_INSTALL_DIR', $null, 'User')` |
| `JAVA_HOME` | `~\scoop\apps\temurin21-jdk\current` | o scoop, ao instalar o JDK | o `scoop uninstall temurin21-jdk` desfaz. ⚠️ Enquanto existir, ela vale **no lugar** do `JAVA_HOME` da máquina (`C:\Program Files\Java\jre-1.8`) para os programas do seu usuário |
| `PATH` (usuário) | `~\scoop\apps\temurin21-jdk\current\bin`, `~\scoop\apps\nodejs-lts\current` e `\bin` | o scoop | o `scoop uninstall` de cada um desfaz |

### O ajuste no registro do REA

O `rea setup` registrou `npx` pelo nome. No Windows o `PATH` da máquina vem antes do do usuário, então o nome achava o Node 22.18, que o REA recusa (exige 22.19+). O registro foi apontado para `~\scoop\apps\nodejs-lts\current\npx.cmd`.

## Ubuntu (WSL `Ubuntu-22.04`)

| Data | O quê | Onde | Como remover |
|---|---|---|---|
| 15/out/2026 | pasta de trabalho: imagem do disco, código gerado, build | `~/pes-work` | `scripts/desinstalar-ubuntu.sh` apaga |
| 15/out/2026 | **134 pacotes**: clang 19.1.7 + libc++ 19 (do `apt.llvm.org`), CMake, Ninja, unzip, p7zip, SDL2, xz e as dependências deles | pacotes do sistema; lista exata em [`apt-instalados.txt`](apt-instalados.txt), gerada pelo próprio script | `scripts/desinstalar-ubuntu.sh` remove a lista, o repositório do LLVM (`/etc/apt/sources.list.d/llvm-19.list`) e a chave dele |
| 15/out/2026 | **Vulkan por software do Mesa** (lavapipe, `mesa-vulkan-drivers` 23.2.1 e `libvulkan1`), **sem instalar no sistema**: baixado com `apt-get download` (sem senha) e extraído com `dpkg -x`; ativa-se por sessão com `. ~/pes-work/vulkan-local/env.sh` | `~/pes-work/vulkan-local` (~40 MB) | sai com `~/pes-work`; nenhum pacote do sistema mudou |
| 15/out/2026 | espelho do recompilador, onde ele compila: código + `games/` (a imagem), `generated/`, `build/`, `tools/emsdk`, `third_party/wgpu-native` | `~/pes-work/recomp` | sai com `~/pes-work` |
| 15/out/2026 | `rsync` | já vinha no Ubuntu | não remover (é do sistema) |
| 15/out/2026 (baixado pelo `setup.sh` do recompilador) | Emscripten 6.0.11 (**1,7 GB**) | `~/pes-work/recomp/tools/emsdk` | sai com `~/pes-work` |
| 15/out/2026 (baixado pelo `setup.sh` do recompilador) | wgpu-native v29.0.1.1 (59 MB) | `~/pes-work/recomp/third_party/wgpu-native` | sai com `~/pes-work` |
| 15/out/2026 (baixado pelo Emscripten no primeiro build web) | porta `emdawnwebgpu` v20260423 (WebGPU para o Emscripten) | cache do Emscripten, dentro de `~/pes-work/recomp/tools/emsdk` | sai com `~/pes-work` |
| 15/out/2026 | versão de navegador do jogo: `ps2web.wasm` (77 MB; 18 MB comprimido) | `~/pes-work/recomp/build/web-pes2012` (fora do git) | sai com `~/pes-work` |

## Devolver o espaço do Ubuntu ao Windows

O disco virtual do WSL cresce e **não encolhe sozinho**. Depois de rodar o `desinstalar-ubuntu.sh`, num PowerShell:

```powershell
wsl --shutdown
wsl --manage Ubuntu-22.04 --set-sparse true
```

## Fora do computador

| O quê | Onde | Como remover |
|---|---|---|
| Repositório privado | `github.com/Gabriel-Alexandre/pes-2012-no-navegador` | `gh repo delete Gabriel-Alexandre/pes-2012-no-navegador` (decisão dele) |
| O arquivo baixado | `Downloads\PES 2012 (PS2).7z` (2,2 GB) | não foi tocado; ele decide se apaga |
