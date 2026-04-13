# Guia ComfyUI + MCP — Geração de Sprites para "Meu Jogo"

## Hardware Alvo
- **GPU**: AMD RX 6750 XT (12GB VRAM)
- **Backend**: DirectML (Windows + AMD)
- **Sprites**: 32x32 pixel art, fundo transparente, dark-fantasy roguelike

---

## 1) Instalação do ComfyUI

### Pré-requisitos
```powershell
# Python 3.10+ deve estar instalado
python --version

# Git deve estar instalado
git --version
```

### Clonar e configurar
```powershell
# Clonar (escolha uma pasta fixa, ex: C:\AI\ComfyUI)
cd C:\AI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

# Criar venv (recomendado)
python -m venv venv
.\venv\Scripts\Activate.ps1

# Instalar dependências para AMD (DirectML)
pip install torch torchvision --index-url https://download.pytorch.org/whl/nightly/cpu
pip install torch-directml
pip install -r requirements.txt
```

### Iniciar ComfyUI
```powershell
cd C:\AI\ComfyUI
.\venv\Scripts\Activate.ps1
python main.py --directml
```

Abra `http://127.0.0.1:8188` no navegador para confirmar que está rodando.

---

## 2) Modelos para Pixel Art

### Checkpoint base (obrigatório — escolha 1)
Baixe e coloque em `ComfyUI/models/checkpoints/`:

- **Stable Diffusion XL** (SDXL): modelo base grande
  - Baixar de: https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0
  - Arquivo: `sd_xl_base_1.0.safetensors`

### LoRA de Pixel Art (obrigatório)
Baixe e coloque em `ComfyUI/models/loras/`:

- **Pixel Art XL LoRA**: especializado em pixel art
  - Buscar no CivitAI: https://civitai.com/models?query=pixel+art+xl
  - Recomendados: "Pixel Art XL", "Pixel Art Style", "16bit Game Assets"
  - Arquivo `.safetensors` vai em `models/loras/`

### VAE (opcional mas recomendado)
- `sdxl_vae.safetensors` em `ComfyUI/models/vae/`

---

## 3) Servidor MCP para ComfyUI

### Instalar comfyui-mcp
```powershell
# No diretório do projeto ou globalmente
npm install -g comfyui-mcp-server
```

OU usar via npx:
```powershell
npx comfyui-mcp-server --comfyui-url http://127.0.0.1:8188
```

### Configurar no Copilot CLI
Editar `C:\Users\<SEU_USER>\.copilot\mcp-config.json`:

```json
{
  "mcpServers": {
    "comfyui": {
      "type": "stdio",
      "command": "npx",
      "args": [
        "comfyui-mcp-server",
        "--comfyui-url",
        "http://127.0.0.1:8188"
      ]
    }
  }
}
```

---

## 4) Sprites a Gerar

### Referência visual
Estilo alvo: **Pixel Dungeon RPG (R2 Games)**
- Pixel art retro dark-fantasy
- 32x32 por sprite
- Fundo transparente
- Contorno escuro 1px
- Paleta curta (3-5 cores por material)
- Camera top-down com leve leitura frontal

### Bloco fixo de prompt (copiar em todos)
```
pixel art sprite, 32x32 canvas, transparent background, one character only,
centered composition, top-down dungeon crawler perspective, readable silhouette,
clean 1px outline, limited color palette, no background, no floor, no UI,
no text, no border, no realistic shading, no anti-alias, no isometric view,
dark fantasy roguelike style, SNES-era palette discipline
```

### Lista completa de sprites necessários

#### Jogadores (4 poses cada: idle, walk, attack, hit)
| ID | Prompt Extra | Paleta |
|----|-------------|--------|
| `spr_player_archer_idle` | archer hero, lean agile body, olive green tunic, leather details, bow clearly visible | Verde oliva + couro |
| `spr_player_archer_walk` | archer walking, slight stride, bow in hand | Verde oliva + couro |
| `spr_player_archer_attack` | archer drawing bow to shoot, dynamic pose | Verde oliva + couro |
| `spr_player_archer_hit` | archer recoiling from damage, defensive pose | Verde oliva + couro |
| `spr_player_mage_idle` | mage hero, purple arcane robe, staff with glowing tip, golden accents | Roxo + azul arcano |
| `spr_player_mage_walk` | mage walking, robe flowing, staff in hand | Roxo + azul arcano |
| `spr_player_mage_attack` | mage casting spell, energy at staff tip | Roxo + azul arcano |
| `spr_player_mage_hit` | mage recoiling from damage, robe and staff visible | Roxo + azul arcano |

#### Pets (3 poses cada: idle, walk, attack)
| ID | Prompt Extra | Paleta |
|----|-------------|--------|
| `spr_pet_guardian_whelp_*` | baby dragon, small loyal companion, warm orange scales, tiny wings | Laranja quente |
| `spr_pet_ranger_hawk_*` | hawk companion, sharp beak, brown feathers, alert predator pose | Marrom + cinza |
| `spr_pet_arcane_fairy_*` | tiny fairy, glowing arcane wings, blue-purple, magical aura | Azul + roxo brilhante |

#### Montarias (2 poses cada: idle, run)
| ID | Prompt Extra | Paleta |
|----|-------------|--------|
| `spr_mount_iron_wolf_*` | armored wolf mount, dark grey fur, metal plate on head | Cinza escuro + metal |
| `spr_mount_royal_stag_*` | majestic stag mount, antlers, noble brown fur, regal bearing | Marrom nobre + dourado |

#### Tiles de Dungeon
| ID | Prompt Extra | Notas |
|----|-------------|-------|
| `tile_floor` | stone dungeon floor, dark gray, subtle crack variations | Fundo opaco |
| `tile_wall` | dungeon wall, lighter stone, rough texture | Fundo opaco |
| `tile_door` | wooden dungeon door, iron bands, medieval | Fundo opaco |
| `tile_stairs` | stone staircase descending into darkness | Fundo opaco |

#### Ícones de Skills (18 — todos 32x32, fundo transparente)
| Classe | Ícone | Prompt Extra |
|--------|-------|-------------|
| Guerreiro | `icon_golpe_brutal` | heavy sword slash, impact effect, steel blade |
| Guerreiro | `icon_investida` | charging forward, motion lines, shield rush |
| Guerreiro | `icon_provocacao` | taunting shout, anger symbol, war cry |
| Guerreiro | `icon_escudo_de_ferro` | iron shield glowing, defensive aura |
| Guerreiro | `icon_pele_de_aco` | metallic skin effect, toughness passive |
| Guerreiro | `icon_vigor_de_batalha` | heart with armor, battle vigor passive |
| Arqueiro | `icon_tiro_preciso` | precise arrow shot, crosshair target |
| Arqueiro | `icon_rajada_tripla` | three arrows fanning out |
| Arqueiro | `icon_flecha_perfurante` | glowing piercing arrow, armor-breaking |
| Arqueiro | `icon_passo_recuado` | backwards dodge, evasion footwork |
| Arqueiro | `icon_olho_de_aguia` | eagle eye, enhanced vision passive |
| Arqueiro | `icon_cacador_nato` | hunter mark, tracking passive |
| Mago | `icon_bola_de_fogo` | fireball, flames, explosive magic |
| Mago | `icon_gelo_cortante` | ice shard, sharp frozen crystal |
| Mago | `icon_raio_arcano` | arcane lightning bolt, purple energy |
| Mago | `icon_escudo_arcano` | magical barrier, runic shield |
| Mago | `icon_sobrecarga_elemental` | elemental overload, multi-element passive |
| Mago | `icon_afinidade_arcana` | arcane affinity, mana crystal passive |

---

## 5) Workflow de Geração

### Passo 1: Iniciar ComfyUI
```powershell
cd C:\AI\ComfyUI
.\venv\Scripts\Activate.ps1
python main.py --directml
```

### Passo 2: No Copilot CLI (outro terminal)
Para cada sprite, rode:
```powershell
copilot -m extrahigh "Usando o ComfyUI MCP, gere o sprite [ID] com o seguinte prompt: [BLOCO_FIXO] + [PROMPT_EXTRA]. Salve como PNG 32x32 com fundo transparente em C:\Users\ss1093839\Desktop\Meu Jogo\assets\characters\[PASTA]\[NOME].png"
```

OU, se preferir sem MCP, use manualmente no ComfyUI web (http://127.0.0.1:8188):
1. Monte um workflow KSampler com SDXL + LoRA de Pixel Art
2. Resolução: 512x512 (depois reduz para 32x32)
3. Prompt: [BLOCO_FIXO] + [PROMPT_EXTRA]
4. Negative prompt: `realistic, photographic, 3d render, isometric, side view, multiple characters, background scene, text, watermark, blurry, anti-aliased`
5. Steps: 25-30, CFG: 7, Sampler: euler_ancestral
6. Salve e reduza para 32x32 com nearest-neighbor (sem interpolação!)

### Passo 3: Redimensionar para 32x32
```powershell
# Instalar ImageMagick se não tiver
# Depois, para cada sprite gerado em 512x512:
magick convert sprite_512.png -resize 32x32 -filter Point sprite_32.png
```

### Passo 4: Integrar no Godot
Copie os PNGs para as pastas corretas:
- `assets/characters/player/` → sprites de jogador
- `assets/characters/enemies/` → sprites de inimigos
- `assets/characters/pets/` → sprites de pets
- `assets/characters/mounts/` → sprites de montarias
- `assets/world/dungeon/` → tiles
- `assets/ui/skills/` → ícones

Atualize os `.tres` correspondentes para apontar para os novos PNGs.

---

## 6) Checklist de Validação

- [ ] Sprite tem fundo realmente transparente (canal alpha)
- [ ] Tamanho final é 32x32
- [ ] Silhueta legível e distinta das outras unidades
- [ ] Sem objetos de cena, chão ou UI no sprite
- [ ] Sem estilo semi-realista ou isométrico
- [ ] Paleta consistente com `ART_DIRECTION.md`
- [ ] Sprite centralizado na célula
- [ ] Teste no Godot: abrir cena, verificar alinhamento no grid

---

## 7) Dica Final

Se o ComfyUI + DirectML der problema na 6750 XT, tente:
```powershell
# Forçar device 0
python main.py --directml 0
```

Se ainda falhar, use `--cpu` (mais lento mas funciona sempre):
```powershell
python main.py --cpu
```
