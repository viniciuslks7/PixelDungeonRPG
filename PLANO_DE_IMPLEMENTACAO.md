# Meu Jogo

## Visao do produto

Objetivo: criar um roguelike RPG 2D top-down, em pixel art, inspirado no ritmo de exploracao e progressao de `Pixel Dungeon`, mas com espaco para evoluir depois para classes, monstros, itens e pets.

Pitch inicial:

- explorar salas
- enfrentar inimigos em combates curtos
- coletar loot
- descer para o proximo andar
- fortalecer o personagem

Meta do primeiro marco:

- entregar um `vertical slice` jogavel
- validar se o loop principal e divertido
- provar a arquitetura base no `Godot 4`

## Decisoes travadas para evitar retrabalho

- Engine: `Godot 4`
- Linguagem: `GDScript`
- Plataforma inicial: `PC`
- Camera: `top-down`
- Movimento: `grid-based`
- Fluxo de jogo: `turn-based`
- Tile size inicial: `32x32`
- Arte inicial: `placeholders` primeiro, assets finais depois
- Dados de conteudo: `Resources` no Godot para classes, monstros, itens e pets

Observacao:

- Se a meta continuar sendo "parecido com Pixel Dungeon", o projeto nao deve nascer com movimento livre.
- O caminho mais seguro e assumir `grid + turnos` desde o primeiro prototipo.

## Core loop do MVP

Loop de 30 segundos:

1. entrar em uma sala
2. se posicionar no grid
3. atacar ou evitar inimigos
4. coletar um item ou recompensa
5. seguir para a proxima sala ou escada

O MVP so esta aprovado quando esse loop estiver claro, rapido e legivel.

## Escopo do vertical slice

Entregavel inicial:

- 1 classe jogavel: `Guerreiro`
- 1 andar de dungeon com geracao procedural simples
- 3 tipos de inimigo: `Slime`, `Skeleton`, `Bat`
- 1 ataque basico corpo a corpo
- 1 sistema de vida, dano e morte
- 1 HUD simples
- 1 inventario minimo
- 4 itens iniciais:
  - `Pocao de Vida`
  - `Espada Curta`
  - `Escudo`
  - `Chave`
- 1 tileset de dungeon
- 5 props basicos:
  - `Bau`
  - `Tocha`
  - `Barril`
  - `Porta`
  - `Escada`
- 1 tela de `game over`

Pet no vertical slice:

- apenas como `spike tecnico opcional` no final
- comportamento maximo: seguir o jogador e atacar inimigo adjacente
- sistema completo de pets fica para depois do MVP

## Fora do MVP

Esses sistemas devem ficar explicitamente fora do primeiro slice:

- multiplas classes jogaveis
- crafting e alquimia
- loja e NPCs complexos
- meta-progressao entre runs
- efeitos complexos de status
- sistema completo de pets
- grande variedade de armas e armaduras
- biomas diferentes

## Arquitetura tecnica inicial

Principios:

- `Scenes` para entidades e salas
- `Resources` para dados de conteudo
- `Signals` para comunicacao desacoplada
- `State Machine` para estados do jogador e inimigos
- `Autoloads` apenas para sistemas realmente globais

Autoloads recomendados:

- `GameManager`
- `TurnManager`
- `SceneManager`

Estrutura de pastas recomendada:

- `autoload/`
- `scenes/main/`
- `scenes/world/`
- `scenes/player/`
- `scenes/enemies/`
- `scenes/items/`
- `scenes/ui/`
- `scripts/components/`
- `scripts/states/`
- `data/classes/`
- `data/monsters/`
- `data/items/`
- `data/pets/`
- `assets/characters/`
- `assets/tilesets/`
- `assets/props/`
- `assets/ui/`
- `audio/`

Padrao de dados recomendado:

- `CharacterClassData` para classe jogavel
- `MonsterData` para monstros
- `ItemData` para itens
- `PetData` para pets

Isso permite crescer conteudo sem reescrever a logica base.

## Modelagem inicial de conteudo

### Classes

MVP:

- `Guerreiro`

Pos-MVP:

- `Ladino`
- `Mago`

### Monstros

MVP:

- `Slime`: lento, simples, melee
- `Bat`: rapido, pouca vida
- `Skeleton`: resistente, pressao frontal

Pos-MVP:

- arqueiros
- casters
- elites
- bosses

### Itens

MVP:

- consumivel
- arma simples
- defesa simples
- chave de progressao

Pos-MVP:

- raridades
- passivos
- itens com efeitos especiais

### Pets

MVP:

- nao obrigatorio
- se entrar, apenas 1 pet simples

Pos-MVP:

- categorias de pets
- progressao de pet
- habilidades especiais

## Ordem ideal de implementacao

### Fase 1 - Bootstrap tecnico

Objetivo: deixar a base do projeto pronta.

- criar o projeto no `Godot 4`
- definir resolucao base e camera
- configurar input map
- configurar pixel snapping
- criar a estrutura de pastas

Criterio de saida:

- projeto abre limpo
- cena principal roda
- pipeline de pastas e naming padrao definidos

### Fase 2 - Grid, turnos e movimentacao

Objetivo: travar o coracao do jogo.

- implementar movimentacao em grid
- implementar turn manager
- fazer cada acao consumir turno
- bloquear inputs invalidos

Criterio de saida:

- jogador se move com previsibilidade
- o loop de turnos esta funcionando

### Fase 3 - Sala de teste manual

Objetivo: validar gameplay sem procedural.

- montar uma sala manual com tilemap
- criar paredes, portas e colisao
- adicionar props placeholder

Criterio de saida:

- o jogador navega em uma sala fechada sem bugs de colisao

### Fase 4 - Combate basico

Objetivo: fechar o primeiro combate funcional.

- ataque melee do jogador
- componente de vida e dano
- morte do jogador e inimigos
- feedback minimo:
  - hit flash
  - som placeholder
  - barra de vida

Criterio de saida:

- o jogador consegue matar um inimigo e morrer para ele

### Fase 5 - Inimigos e IA

Objetivo: criar pressao de jogo.

- implementar `Slime`
- implementar `Bat`
- implementar `Skeleton`
- IA simples:
  - perseguir no grid
  - atacar adjacente
  - respeitar turnos

Criterio de saida:

- tres inimigos funcionam com comportamento previsivel

### Fase 6 - Itens, loot e inventario minimo

Objetivo: introduzir recompensa.

- drop no chao
- coleta de item
- inventario simples
- uso de pocao
- equipamento simples de arma ou defesa
- bau com recompensa

Criterio de saida:

- o jogador coleta, guarda e usa pelo menos um item

### Fase 7 - Dungeon procedural v1 e progressao

Objetivo: transformar o prototipo em roguelike.

- geracao simples de salas e corredores
- spawn de inimigos e loot por sala
- escada para proximo andar
- progressao minima do jogador

Criterio de saida:

- uma run curta pode ser jogada do inicio ao fim

### Fase 8 - UI, polish e spike de pet

Objetivo: preparar uma demo apresentavel.

- HUD final minima
- tela de `game over`
- ajuste de contraste e leitura
- onboarding dos primeiros 30 segundos
- balanceamento inicial
- testar um pet simples apenas se o loop principal ja estiver estavel

Criterio de saida:

- o vertical slice pode ser mostrado para teste externo

## Pipeline de arte

Ferramentas:

- `PixelLab MCP` para geracao inicial de assets
- `Aseprite` ou `Pixelorama` para refinamento manual

Regra de pipeline:

1. validar gameplay com placeholders
2. fixar paleta e direcao visual
3. gerar pacote inicial de heroi, inimigos, tileset e props
4. corrigir manualmente o que a IA nao resolver bem
5. versionar tudo com `Git`

Boas praticas:

- usar prompts consistentes entre heroi, inimigos e props
- manter silhueta clara
- priorizar leitura do jogador e inimigos sobre detalhe
- nao misturar estilos de asset

## Riscos principais

- escopo crescer antes do loop principal ficar divertido
- tentar fazer pets cedo demais
- procedural complexa antes da sala manual estar boa
- inventario nascer rigido e travar expansao futura
- inconsistencia visual entre assets gerados por IA
- tile size ruim prejudicar leitura e hit feedback

## Skills mais relevantes para este projeto

### Essenciais agora

- `2d-games`
  - tilemap, camera, colisao, sprite e fundamentos 2D
- `game-design`
  - core loop, progressao, dificuldade e definicao de MVP
- `game-development`
  - skill orquestradora para decidir plataforma, escopo e especialidades
- `godot-gdscript-patterns`
  - arquitetura em `Scenes`, `Resources`, `Signals`, `State Machines`

### Relevantes nas proximas fases

- `game-art`
  - pipeline visual, paleta, animacao e consistencia de assets
- `pc-games`
  - escolha de engine, profiling e plataforma inicial no desktop
- `game-audio`
  - quando entrar em efeitos sonoros, trilha e feedback de combate

### Nao prioritarias neste momento

- `3d-games`
- `multiplayer`
- `vr-ar`

Essas skills so entram se o escopo do projeto mudar.

## Proximos passos recomendados

1. criar o projeto base no `Godot 4`
2. implementar `grid + turnos` antes de qualquer sistema extra
3. montar uma sala manual com placeholders
4. fechar combate com 1 inimigo
5. so depois abrir a frente de assets e procedural
