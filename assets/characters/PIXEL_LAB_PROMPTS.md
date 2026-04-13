# Pixel Lab Prompts

## Uso

Estes prompts foram escritos para gerar a primeira leva de sprites do `vertical slice`.

Meta desta rodada:

- gerar `1 sprite idle estatico` por unidade
- `32x32`
- fundo transparente
- leitura forte em jogo `top-down grid-based`

## Bloco fixo

Use sempre estas restricoes junto com o prompt principal:

```text
pixel art sprite, 32x32 canvas, transparent background, one character only, centered composition, top-down dungeon crawler perspective, readable silhouette, clean 1px outline where needed, limited color palette, no background, no floor, no UI, no text, no border, no realistic shading, no anti-alias blur, no isometric view, no side view
```

## Prompt 1 - Guerreiro

Nome do arquivo sugerido:

`spr_player_warrior_idle.png`

Prompt:

```text
Create a pixel art sprite for a warrior hero in a dark fantasy roguelike. 32x32 canvas, transparent background, one character only, centered composition, top-down dungeon crawler perspective with slight frontal readability. Broad shoulders, compact body, blue desaturated tunic, brown leather belt and boots, warm metal accents, short sword visible but not oversized, small shield or armored off-hand allowed, heroic but practical look, strong silhouette, readable at very small size, retro SNES-inspired palette discipline.
```

## Prompt 2 - Slime

Nome do arquivo sugerido:

`spr_enemy_slime_idle.png`

Prompt:

```text
Create a pixel art sprite for a green slime enemy in a dark fantasy roguelike. 32x32 canvas, transparent background, one character only, centered composition, top-down dungeon crawler perspective. Rounded gelatinous body, low silhouette, bright green main body with darker inner core, subtle gooey highlights, irregular base, simple hostile creature design, readable at very small size, cute-dangerous balance, clean retro pixel art.
```

## Prompt 3 - Esqueleto

Nome do arquivo sugerido:

`spr_enemy_skeleton_idle.png`

Prompt:

```text
Create a pixel art sprite for a skeleton enemy in a dark fantasy roguelike. 32x32 canvas, transparent background, one character only, centered composition, top-down dungeon crawler perspective with slight frontal readability. Thin humanoid bone structure, skull clearly readable, yellowed bones, scraps of rusty armor, dark gaps between ribs and limbs, small rusted weapon or shield fragment allowed, menacing but simple, readable silhouette, classic dungeon enemy look.
```

## Prompt 4 - Morcego

Nome do arquivo sugerido:

`spr_enemy_bat_idle.png`

Prompt:

```text
Create a pixel art sprite for a bat enemy in a dark fantasy roguelike. 32x32 canvas, transparent background, one character only, centered composition, top-down dungeon crawler perspective. Small body, wide wings forming a strong X or diamond silhouette, dark purple and cold gray palette, tiny aggressive face, fast and fragile feel, strong contrast, readable at very small size, retro dungeon monster sprite.
```

## Segunda passada opcional

Depois de aprovar os sprites estaticos, pedir sheets separados.

### Guerreiro idle sheet

```text
Create a 4-frame idle spritesheet for the same warrior hero sprite. Keep the exact same design, palette, scale, and silhouette consistency. Minimal breathing and cloth movement only. Transparent background, pixel art, 32x32 per frame.
```

### Slime wobble sheet

```text
Create a 4-frame idle wobble spritesheet for the same green slime sprite. Keep the exact same design, palette, scale, and silhouette consistency. Subtle squash and stretch, gelatin movement only. Transparent background, pixel art, 32x32 per frame.
```

### Esqueleto idle sheet

```text
Create a 4-frame idle spritesheet for the same skeleton enemy sprite. Keep the exact same design, palette, scale, and silhouette consistency. Minimal bone sway and tiny armor movement only. Transparent background, pixel art, 32x32 per frame.
```

### Morcego flap sheet

```text
Create a 4-frame flying idle spritesheet for the same bat enemy sprite. Keep the exact same design, palette, scale, and silhouette consistency. Wing flap motion only, fast and light feel. Transparent background, pixel art, 32x32 per frame.
```

## Criterios de aprovacao

Aceitar apenas sprites que cumpram tudo abaixo:

- leitura clara em `32x32`
- fundo realmente transparente
- unidade centralizada
- silhueta distinta das outras
- sem objetos de cena junto
- sem estilo semi-realista
- sem perspectiva lateral ou isometrica

## Observacao de pipeline

O projeto ainda usa `DebugBody` como placeholder em:

- `scenes/player/player.tscn`
- `scenes/enemies/enemy.tscn`

Quando os PNGs forem aprovados, a proxima etapa e integrar `Sprite2D` ou `AnimatedSprite2D` nessas cenas sem alterar a logica de combate e turno.
