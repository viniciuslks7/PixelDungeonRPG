# Handoff de Arte - 2026-04-10

## Objetivo da sessao

Preparar a primeira leva de arte jogavel para o `vertical slice`:

- `Guerreiro`
- `Slime`
- `Esqueleto`
- `Morcego`

## Restricao encontrada

O `pixel lab MCP` nao esta exposto nesta sessao do Codex. Portanto, a geracao de imagem nao pode ser executada daqui hoje.

## O que foi salvo no projeto

- direcao visual em `assets/characters/ART_DIRECTION.md`
- prompts de geracao em `assets/characters/PIXEL_LAB_PROMPTS.md`

## Estado atual relevante

- `player.tscn` ainda usa `DebugBody`
- `enemy.tscn` ainda usa `DebugBody`
- o projeto continua funcional com placeholders
- a validacao headless conhecida continua sendo o gate tecnico

## Proxima sessao recomendada

1. Usar `PIXEL_LAB_PROMPTS.md` para gerar os 4 sprites idle base.
2. Exportar PNG com fundo transparente.
3. Salvar os arquivos em:
   - `assets/characters/player/`
   - `assets/characters/enemies/`
4. Integrar primeiro os sprites estaticos.
5. So depois gerar sheets de animacao.

## Ordem de integracao sugerida

1. `Guerreiro`
2. `Slime`
3. `Esqueleto`
4. `Morcego`

## Regra para nao quebrar o projeto

Substituir apenas a representacao visual das cenas antes de expandir animacao. Nao mexer primeiro em `TurnManager`, `EventBus` ou no loop de combate.
