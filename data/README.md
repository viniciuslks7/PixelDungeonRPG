# Data Layer

Use os scripts em `res://scripts/resources/` como base para criar instancias `.tres` em:

- `res://data/classes/`
- `res://data/monsters/`
- `res://data/items/`
- `res://data/pets/`

Convencoes iniciais:

- um arquivo `.tres` por classe, monstro, item ou pet
- `id` deve ser estavel e em `snake_case`
- `display_name` pode ser amigavel para UI
- balanceamento vai nos `.tres`, nao nos scripts `.gd`

Exemplos de ids previstos para o MVP:

- classe: `guerreiro`
- monstros: `slime`, `bat`, `skeleton`
- itens: `pocao_vida`, `espada_curta`, `escudo`, `chave_andar`
- pet futuro: `slime_pet`
