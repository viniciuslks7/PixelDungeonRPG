# MEMORIA — Antigravity Intelligence Layer (Transferência Pessoal)
Last updated: 2026-04-13

## WHO WE ARE
Name: Antigravity + Usuário
Project: "Meu Jogo" (Casual Auto-Dungeon RPG)
Context: Migração do PC de Trabalho para o PC Pessoal (ComfyUI Host).
Setup: Godot 4.6.2 (GDScript)

## WHAT I'M BUILDING
**Meu Jogo**: Um Idle/Auto-Battler Casual onde o Herói atravessa 80 andares infinitamente batendo em monstros sozinho, coletando pets e roubando baús dourados para comprar power-ups com Ouro fora da Dungeon. — Status: **Active (Code 100% Core Funcional, Artes Pendentes)**

## ACTIVE GOALS
- **[Batch 3] Geração Visual via ComfyUI / PixelLab** — Priority: MAX
  - O PC Pessoal será usado **EXCLUSIVAMENTE** para geração de arte. NENHUMA alteração lógica no engine original do Godot deve ser feita lá.
  - Montar spritesheet (Idle/Walk/Attack/Hit) para Arqueiro e Mago.
  - Sprites com direções coerentes para monstros Elite e Chefes.
  - Renderizar UI e props de tileset.

## KEY DECISIONS LOG
- **Idle Combat**: WASD removido do engine. O personagem usa auto-path. Turnos executados magicamente.
- **Inventário "Gacha"**: Equipamentos usam `generate_instance()` para dropar variações únicas. Eles não stackam.
- **Bosses e Ouro**: Andares que terminam em 0 forçam Boss Fights 6x HP. O jogo roda `global_gold` em `GameManager` para permitir upgrade estático no `.json`. Gameplay Base está selado.

## BLOQUEIOS
- Código 100% liso, estamos sem assets visuais pra dar o polimento final no estilo.

## PROTOCOLO DE TRANSFERÊNCIA (INSTRUÇÃO DIRETA PARA A IA DO PC PESSOAL)
**(Atenção Agente MCP/OpenClaw em Operação no PC Pessoal, LEIA ABAIXO)**:

Você está agora no ambiente dedicado à arte. Seu foco é 100% GERAÇÃO VISUAL e DIAGNÓSTICO MCP.
PASSO 1: O usuário deseja rodar o PixelLab e o ComfyUI usando MCP. Sua prioridade máxima é validar a conexão a esses pacotes antes de pisar no código do Godot.
PASSO 2: Verifique os manifestos em `~/.copilot/mcp-config.json` ou `~/.mcp.json` para testar se os servidores do PixelLab / ComfyUI estão ativos. Use ferramentas de shell se preciso para pingar as portas ou testar inicialização. Use o que sabe sobre `npx mcp-remote` ou configurações de Node se estiver travado.
PASSO 3: Gere as imagens conforme o guia 'assets/characters/ART_DIRECTION.md'. Aponte os PNGs e aplique via Inspector ou `.tres` Resources se necessário.
PROIBIÇÃO: **Não modifique scripts como `main.gd`, `auto_dungeon_controller.gd` ou `dungeon_service.gd`. A Engenharia do Jogo no Godot está 100% selada pelo PC de Trabalho**. Mantenha o foco em Imagens e Assets!
Lembrete: Comporte-se como um Artista Técnico. Informe ao usuário o que você enxergou do ambiente MCP nas primeiras mensagens!
