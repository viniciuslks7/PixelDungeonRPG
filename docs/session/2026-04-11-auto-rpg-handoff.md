# Handoff Auto RPG Expandido - 2026-04-11

## Objetivo da rodada

Consolidar o MVP expandido do auto-RPG com:

- HUD interativa de hub central
- inventario realmente operavel em runtime
- pet e montaria equipaveis com impacto real de atributos
- base artistica inicial integrada para classes e skills

## Entregas concluidas hoje

1. HUD interativa com popup funcional para `Personagem`, `Inventario`, `Skills`, `Pet`, `Montaria`.
2. Inventario com interacao manual:
   - `1-9` para equipar/usar item listado
   - `Q` para desequipar arma
   - `E` para desequipar escudo
3. Integracao HUD -> Main:
   - sinais para equipar/usar item
   - sinais para ciclar pet/montaria
4. Sistema de pet/montaria aplicado no player:
   - bonus em `ATK`, `DEF`, `HP` e velocidade de movimento
   - recalculo imediato de `Poder Geral`
5. Conteudo de progressao:
   - 3 pets iniciais (`guardian_whelp`, `ranger_hawk`, `arcane_fairy`)
   - 2 montarias iniciais (`iron_wolf`, `royal_stag`)
   - 4 itens extras de equipamento (`elmo`, `armadura`, `luvas`, `botas`)
6. Loot de bau escalado por tier atualizado para incluir novos itens de slot.
7. Arte MVP ampliada:
   - sprite idle de `Arqueiro`
   - sprite idle de `Mago`
   - 3 icones de familias de skill (`warrior`, `archer`, `mage`)
   - 18 skills com `icon` definido nos recursos `.tres`
8. Classes com sprites de acao dedicados:
   - `walk`, `attack`, `hit` para `Guerreiro`, `Arqueiro`, `Mago`
   - troca temporaria de sprite integrada ao runtime do `Player`
9. Skills com icones unicos por recurso:
   - 18 arquivos em `assets/ui/icons/skills/`
   - todos `data/skills/*.tres` apontando para icone especifico da skill
10. Companions com pacote visual completo:
   - pets com `idle/walk/attack`
   - montarias com `idle/run`
   - runtime de `Pet`/`Mount` atualizado para swap de sprite por acao
11. Dungeon visual consolidada:
   - tiles `floor/wall` e props `torch/altar/stairs`
   - `TestRoom` renderizando textura com fallback
   - `DungeonProp` com `Sprite2D` + fallback draw
12. Correcoes de fechamento (runtime):
   - rotas de auto-dungeon ajustadas para nao atravessar celulas bloqueadas do mapa
   - acao de inventario via HUD (equip/consumivel/unequip) agora passa por `TurnManager.begin_resolution()` e `resolve_player_action()`

## Arquivos-chave desta rodada

- Runtime/UI:
  - `scripts/ui/game_hud.gd`
  - `scenes/ui/game_hud.tscn`
  - `scripts/main/main.gd`
  - `scripts/player/player.gd`
- Dados novos:
  - `data/pets/*.tres`
  - `data/mounts/*.tres`
  - `data/items/leather_*.tres`
- Resources:
  - `scripts/resources/pet_data.gd`
  - `scripts/resources/mount_data.gd`
- Arte:
  - `assets/characters/player/spr_player_archer_idle.svg`
  - `assets/characters/player/spr_player_mage_idle.svg`
  - `assets/ui/icons/skill_warrior.svg`
  - `assets/ui/icons/skill_archer.svg`
  - `assets/ui/icons/skill_mage.svg`

## Estado atual do backlog (SQL)

Concluidos:

- `generate-character-sprite-packs`
- `generate-equipment-item-icons`
- `generate-pet-mount-assets`
- `generate-skill-icons-vfx`
- `generate-dungeon-tiles-props`

Em andamento:

- `final-polish-release-candidate`

## Estado tecnico atualizado

- `pwsh` instalado com sucesso (PowerShell 7.6.0).
- `acceptance-test-suite` executada e marcada como `done`.
- validacao atual: `VALIDATION PASSED: core loop attack dummy`.

## Incrementos apos desbloqueio do pwsh

1. Integracao de animacoes runtime (`Player` e `Enemy`) para movimento/ataque/hit.
2. Integracao visual de pet e montaria no personagem (companions em runtime).
3. Implementacao de props de dungeon (`torch`, `altar`, `stairs`) por floor.
4. Rebalanceamento das curvas de HP/ATK da dungeon 1..80 por blocos.
5. Pacote de icones dedicados para equipamentos (`helmet/armor/gloves/boots`) e companions (3 pets + 2 mounts).
6. Reimport dos novos assets SVG com Godot headless para garantir carga em runtime.

## Proximo passo recomendado

1. fechar o `final-polish-release-candidate` com checklist final de aceite visual/gameplay;
2. revisar pequenos ajustes de leitura visual (escala/contraste) em HUD e companions;
3. consolidar entrega para branch/release com evidencia de validacao.
