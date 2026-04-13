# Direcao de Arte dos Personagens

## Objetivo

Definir a base visual do `vertical slice` para substituir os placeholders atuais de `Polygon2D` por sprites de pixel art coerentes com o loop do jogo.

Escopo desta fase:

- `Guerreiro`
- `Slime`
- `Esqueleto`
- `Morcego`

Escopo expandido do MVP atual:

- classes jogaveis:
  - `Guerreiro`
  - `Arqueiro`
  - `Mago`
- skills:
  - 18 icones (4 ativas + 2 passivas por classe)
- equipamentos:
  - capacete, armadura, luvas, botas, escudo, arma de classe
- suporte visual para:
  - `Pets`
  - `Montarias`
- UI principal:
  - icones de `Personagem`, `Inventario`, `Skills`, `Pet`, `Montaria`, `Dungeon`
- dungeon:
  - props e baus com progressao visual por tier

## Contexto tecnico do projeto

- jogo `2D top-down`
- movimento em `grid`
- celula base: `32x32`
- viewport atual: `1280x720`
- filtro de textura: `nearest` (`default_texture_filter=0`)

Isso exige sprites extremamente legiveis em tamanho pequeno. O jogador precisa reconhecer a unidade em menos de 1 segundo.

## Alvo visual

- estilo: `pixel art retro dark-fantasy`
- leitura: forte silhueta em `32x32`
- camera: `top-down` com leve leitura frontal
- acabamento: limpo, com contorno escuro e volumes simples
- humor: dungeon classica, hostil, mas com identidade clara por inimigo

Referencia de sensacao:

- dungeon classica
- formas simples
- contraste alto
- pouco ruido visual

## Regras de sprite

- fundo `transparente`
- um personagem por imagem
- composicao centralizada
- sprite ocupando entre `70%` e `85%` da area util
- contorno externo escuro de `1px` quando ajudar a leitura
- sem anti-alias manual
- sem brilho realista
- sem detalhes finos que somem em `32x32`
- priorizar leitura de forma antes de detalhe

## Regras de paleta

- usar paleta curta por unidade
- `3 a 5` valores por material principal
- sombra sempre mais escura e mais fria que a base
- highlight economico, apenas para separar volumes
- evitar saturacao maxima em todos os materiais ao mesmo tempo

Paleta funcional por categoria:

- classes jogaveis:
  - Guerreiro: azul aco + couro marrom + metal
  - Arqueiro: verde oliva + couro + madeira
  - Mago: roxo profundo + azul arcano + detalhes dourados
- UI:
  - fundo escuro frio
  - acento dourado para destaque
  - icones com contraste alto para leitura rapida
- dungeon:
  - pedra fria dominante
  - acentos quentes em tochas e baus

## Anti-padroes

- nao gerar personagem em vista lateral
- nao gerar sprite com perspectiva isometrica
- nao usar anatomia realista
- nao adicionar background, chao, moldura ou UI
- nao criar arma maior que a leitura da celula permite
- nao usar dithering pesado
- nao usar pillow shading

## Identidade por unidade

### Guerreiro

- papel: classe base do jogador
- leitura: robusto, confiavel, linha de frente
- silhueta: ombros largos, tronco compacto
- cores principais: azul dessaturado, couro marrom, metal quente
- detalhe-chave: espada curta e/ou escudo pequeno legivel sem poluir

### Arqueiro

- papel: dano sustentado a distancia
- leitura: leve, agil, postura de mira
- silhueta: corpo enxuto, arco bem reconhecivel
- cores principais: verde oliva, couro claro, madeira escura
- detalhe-chave: arco destacado sem esconder torso

### Mago

- papel: dano elemental e controle
- leitura: conjurador com foco em cast
- silhueta: cajado evidente, capa/roupa arcana
- cores principais: roxo, azul arcano, acento dourado discreto
- detalhe-chave: ponta do cajado e runas precisam ser legiveis em 32x32

### Slime

- papel: inimigo lento e simples
- leitura: massa gelatinosa, redonda, baixa
- silhueta: cupula larga com base irregular
- cores principais: verde vivo com nucleo mais escuro
- detalhe-chave: sensacao de viscosidade, nao de criatura solida

### Esqueleto

- papel: inimigo resistente
- leitura: morto-vivo melee, mais perigoso que o slime
- silhueta: humanoide fino com cabeca ossea bem marcada
- cores principais: osso amarelado, ferrugem, cinza escuro
- detalhe-chave: resto de armadura ou arma enferrujada para reforcar ameaca

### Morcego

- papel: inimigo rapido e fragil
- leitura: pequeno, nervoso, agressivo
- silhueta: asas abertas em formato de losango ou "X"
- cores principais: roxo escuro, cinza frio, acento avermelhado opcional
- detalhe-chave: asas devem comunicar velocidade mesmo parado

### Pets (guia rapido)

- leitura instantanea em 32x32
- formas amigaveis, mas combate claro
- manter 1 detalhe de assinatura por pet (orelhas, nucleo, cauda)

### Montarias (guia rapido)

- silhueta larga e estavel
- prioridade para leitura de deslocamento em loop curto
- nao exagerar detalhe em sela/armadura

## Diretrizes para icones (skills/equip/UI)

- dimensao base: `32x32`
- fundo transparente
- 1 conceito por icone
- borda escura de 1px quando necessario para contraste
- sem texto dentro do icone
- variar forma para memorabilidade:
  - ataque fisico: laminas/pontas
  - magia: runas/energia
  - defesa: escudo/barreira
  - mobilidade: setas/trilha

## Animacoes obrigatorias por entidade

Classes:

- `idle` (4 frames)
- `walk` (4 a 6 frames)
- `attack` (4 frames)
- `cast` (4 frames)
- `hit` (2 frames)
- `death` (4 a 6 frames)

Pets:

- `idle`, `walk`, `attack`

Montarias:

- `idle`, `run`

Dungeon props:

- bau: `closed`, `open`

## Ordem de producao recomendada

### Passo 1

Gerar `1 sprite idle estatico` por unidade.

### Passo 2

Escolher a direcao visual final e ajustar paleta/coerencia.

### Passo 3

Gerar variacoes curtas de animacao:

- `idle` em `4 frames`
- `move` em `4 frames`
- `attack` em `3 a 4 frames` apenas para o guerreiro e esqueleto
- `wobble` em `4 frames` para slime
- `flap` em `4 frames` para morcego

## Naming sugerido

- `spr_player_warrior_idle.png`
- `spr_enemy_slime_idle.png`
- `spr_enemy_skeleton_idle.png`
- `spr_enemy_bat_idle.png`

Se houver sheet:

- `spr_player_warrior_sheet.png`
- `spr_enemy_slime_sheet.png`
- `spr_enemy_skeleton_sheet.png`
- `spr_enemy_bat_sheet.png`

## Integracao futura

Quando os sprites estiverem prontos:

- trocar `DebugBody` por `Sprite2D` ou `AnimatedSprite2D`
- manter `GridMovement` e `Health` intactos
- validar alinhamento do pivot no centro da celula
- conferir se a leitura continua forte na sala de teste
