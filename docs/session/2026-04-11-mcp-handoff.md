# Handoff MCP + Arte (2026-04-11)

## Objetivo desta documentacao

Registrar tudo que foi feito para continuar rapido no dia seguinte, com contexto suficiente para:

- GitHub Copilot CLI / Codex CLI
- Gemini CLI
- qualquer outro agente que use MCP

Este arquivo e a fonte de verdade da rodada de integracao PixelLab.

---

## 1) Resumo executivo

- O projeto de jogo esta funcional no core loop (grid + turno + combate).
- A fase de arte ainda esta pendente (sprites finais nao gerados).
- O acesso ao PixelLab via MCP foi estabilizado em nivel de usuario no ambiente atual.
- O projeto ficou com `.mcp.json` neutro para nao conflitar com config global.
- Prompts e direcao visual ja existem e estao prontos para uso.
- No runtime atual, as tools nativas `pixellab-*` passaram a aparecer no catalogo do agente.

---

## 2) O que foi feito nesta sessao

1. Mapeamento da estrutura atual do projeto e confirmacao do estado do gameplay.
2. Tentativa de setup MCP via `uvx` (fluxo local) para `pixellab`.
3. Bloqueio encontrado: runtime local sem suporte para esse caminho.
4. Migracao para setup remoto com `npx mcp-remote@latest`.
5. Reload/validacao da configuracao MCP.
6. Preparacao de handoff multi-agente para continuidade sem retrabalho.

---

## 3) Estado atual de arquivos relevantes

### Projeto (repo)

- `C:\Users\ss1093839\Desktop\Meu Jogo\.mcp.json`
  - estado esperado: neutro (`{"servers": {}}`)
  - motivo: evitar sobrescrever/duplicar a config ativa global

- `C:\Users\ss1093839\Desktop\Meu Jogo\assets\characters\ART_DIRECTION.md`
  - direcao visual final de referencia

- `C:\Users\ss1093839\Desktop\Meu Jogo\assets\characters\PIXEL_LAB_PROMPTS.md`
  - prompts prontos dos 4 sprites base

### Usuario (fora do repo)

- `C:\Users\ss1093839\.copilot\mcp-config.json`
  - config MCP ativa para `pixellab`
  - escopo: usuario/global
  - nao comitar
  - se houver token literal neste arquivo, substituir por variavel e rotacionar segredo

---

## 4) Configuracao recomendada por cliente (sem segredo hardcoded)

> Regra: use variavel de ambiente. Nao gravar token real em repo.

### 4.1 Copilot CLI / GitHub Copilot (JSON)

```json
{
  "mcpServers": {
    "pixellab": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "mcp-remote@latest",
        "https://api.pixellab.ai/mcp",
        "--transport",
        "http-only",
        "--header",
        "Authorization:${AUTH_HEADER}"
      ],
      "env": {
        "AUTH_HEADER": "Bearer ${PIXELLAB_SECRET}"
      }
    }
  }
}
```

### 4.2 Codex CLI (TOML)

```toml
[mcp_servers.pixellab]
command = "npx"
args = [
  "mcp-remote@latest",
  "https://api.pixellab.ai/mcp",
  "--transport",
  "http-only",
  "--header",
  "Authorization:${AUTH_HEADER}"
]

[mcp_servers.pixellab.env]
AUTH_HEADER = "Bearer ${PIXELLAB_SECRET}"
```

### 4.3 Gemini CLI (JSON)

```json
{
  "mcpServers": {
    "pixellab": {
      "httpUrl": "https://api.pixellab.ai/mcp",
      "headers": {
        "Authorization": "Bearer ${PIXELLAB_SECRET}"
      }
    }
  }
}
```

---

## 5) Seguranca (obrigatorio antes de continuar)

1. Se token foi exposto em chat, considerar comprometido.
2. Revogar e gerar novo token no PixelLab.
3. Atualizar apenas variavel de ambiente:
   - `PIXELLAB_SECRET=<novo_token>`
4. Evitar salvar token literal em:
   - arquivos do projeto
   - commits
   - docs versionadas

---

## 6) Pendencias reais (arte)

Status atualizado (2026-04-11): concluido.

Arquivos gerados:

- `assets/characters/player/spr_player_warrior_idle.png`
- `assets/characters/enemies/spr_enemy_slime_idle.png`
- `assets/characters/enemies/spr_enemy_skeleton_idle.png`
- `assets/characters/enemies/spr_enemy_bat_idle.png`

Pastas `assets/characters/player/` e `assets/characters/enemies/` criadas.

---

## 7) Runbook para o proximo dia (qualquer agente)

1. Ler este arquivo e `assets/characters/PIXEL_LAB_PROMPTS.md`.
2. Confirmar MCP `pixellab` ativo no cliente atual.
3. (Se necessario) regenerar os 4 sprites idle base com fundo transparente.
4. Validar:
    - arquivo existe
    - tamanho > 0 bytes
    - leitura boa em 32x32
5. Integrar visual:
    - trocar `DebugBody` por `Sprite2D` em `player.tscn` e `enemy.tscn`
    - preferir binding data-driven (`idle_sprite` nos `.tres`)
    - manter `GridMovement`, `Health`, `TurnManager`, `EventBus` sem mudanca
6. Rodar validacao tecnica conhecida:
    - `scripts/tests/run_godot_validation.ps1`

---

## 8) Definicao de pronto desta etapa de arte

Esta etapa so fecha quando:

- os 4 PNGs existirem com nomes finais
- placeholders forem removidos das cenas de player/enemy
- gameplay continuar funcional sem regressao no loop de turno/combate

---

## 9) Observacao importante para agentes

Se o cliente ja expor tools nativas `pixellab-*`, prefira essas tools diretas.
Se nao expor, use o caminho MCP remoto (`npx mcp-remote`) com a mesma URL e header.
