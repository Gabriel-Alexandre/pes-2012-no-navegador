# Plano

Aprovado por ele em 15/out/2026. O estado de cada marco mora no [`ESTADO.md`](../ESTADO.md); este arquivo é o desenho.

## Objetivo

O PES 2012 de PS2 rodando **no navegador desta máquina** (Chrome, WebGPU), jogável do menu até uma partida inteira, com som e controle. **Uso local.** Nenhuma versão hospedada, nenhum arquivo do jogo no git.

Plano B: se o navegador não chegar a uma taxa de quadros jogável, fica a versão **nativa** no PC, que o recompilador gera junto.

## A técnica

Recompilação estática pelo [ps2-web-recomp](https://github.com/snuri00/ps2-web-recomp): o executável do jogo (`SLES_556.58`) é traduzido instrução por instrução para C++, compilado para WebAssembly, e roda dentro de um PS2 reimplementado (kernel, processador de entrada e saída, unidades vetoriais, chip gráfico em WebGPU, som). Os arquivos do jogo (modelos, sons, vídeos) são lidos da imagem do disco durante o jogo.

Quando o jogo travar numa peça do PS2 que falta, o diagnóstico é feito lendo o executável no **Ghidra** com o plugin do processador do PS2, pelo **REA** (o agente conversa com o Ghidra) ou pelo Ghidra direto.

## O jogo

| | |
|---|---|
| Versão | **SLES-55658**, PAL europeia, menus em espanhol, italiano, português e grego |
| Imagem | MD5 `c6a29549273f60475a6765791886eae6`, 2.670.395.392 bytes |
| Executável | `SLES_556.58` (3,3 MB) |
| Vídeo | PAL, com opção de 60 Hz: cada vídeo do disco existe em duas versões (`_N` e `_P`) |
| Módulos do processador de entrada e saída (IOP) | `IOPRP300.IMG`, `AUDIO`, `CDVDSTM`, `CRI_ADXI`, `LIBSD`, `MCMAN`, `MCSERV`, `MTAPMAN`, `PADMAN`, `SDRDRV`, `SIO2MAN`, `USBD`, `USBKEYBD`, `USBPSPCM` |

## Os marcos

| Marco | O que acontece | Ponto de parada |
|---|---|---|
| **0. Bancada** | ferramentas instaladas e registradas, recompilador compilado, REA ligado ao Ghidra com o plugin do PS2 | se o REA não usar o Ghidra do PS2, segue com o Ghidra direto |
| **1. A imagem** | extrair, conferir o MD5, guardar em `~/pes-work/games/pes2012/disc.iso` | MD5 diferente: extrair de novo |
| **2. Primeira tradução** | `port.sh` no PES e a lista do que faltou | 🔴 **decisão dele**: ver a lista, com tamanho estimado, e decidir se segue |
| **3. Abrir o jogo** | logos, vídeos de abertura, menus, memory card | a mesma falha sem andar depois de várias tentativas: parar e mostrar |
| **4. A partida** | 22 jogadores, gramado, torcida, com toques programados (`--press`) | |
| **5. Som e controle** | narração, torcida, músicas, controle e teclado; **ele joga para validar** | |
| **6. Navegador** | Chrome com WebGPU, meta de 60 fps no modo 60 Hz | abaixo do jogável: fica a versão nativa |
| **7. Publicação** | só se ele decidir: o repositório como ferramenta "traga o seu disco" | |
| **8. Bomba Patch** | bônus, só como patch sobre um disco | |

## Os riscos, na ordem em que aparecem

1. ~~**Módulos que nenhum jogo testado usou.**~~ ✅ Os 12 módulos do disco carregaram sem biblioteca faltando (15/out).
1. 🔴 **Overlays de código `MWo3` da Konami** (`OVER.AFS`), carregadas em endereços fixos durante o jogo. O recompilador só conhece o formato SNR2. É o que trava hoje (ver `ESTADO.md`).
2. O recompilador só levou dois jogos até o fim.
3. A taxa de quadros de um jogo com 22 jogadores animados ao mesmo tempo.
4. A diferença de último bit nas contas das unidades vetoriais, que o próprio recompilador declara.

## Como se trabalha

- **Uma sessão por marco.** O estado fica no `ESTADO.md`, e a sessão seguinte começa por ele.
- **Commit e push a cada iteração**, aqui e no repositório de documentação dele (`LOW_TICKET`, registro em `contexto/projetos-externos/PES_2012_NO_NAVEGADOR.md`).
- **Toda instalação entra em `docs/INSTALADOS.md` no mesmo passo.**
- Toda mudança no recompilador entra na tabela de `docs/RECOMPILADOR.md`, com o porquê.
