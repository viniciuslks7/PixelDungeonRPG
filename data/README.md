# Data Layer

Use os scripts em `res://scripts/resources/` como base para criar instancias `.tres` em:

- `res://data/classes/`
- `res://data/monsters/`
- `res://data/items/`
- `res://data/skills/`
- `res://data/pets/`

Convencoes iniciais:

- um arquivo `.tres` por classe, monstro, item ou pet
- um arquivo `.tres` por habilidade ativa/passiva
- `id` deve ser estavel e em `snake_case`
- `display_name` pode ser amigavel para UI
- `idle_sprite` deve apontar para o PNG oficial da unidade quando houver arte pronta
- balanceamento vai nos `.tres`, nao nos scripts `.gd`

Exemplos de ids previstos para o MVP:

- classe: `guerreiro`
- monstros: `slime`, `bat`, `skeleton`
- itens: `pocao_vida`, `espada_curta`, `escudo`, `arco_longo`, `cajado_iniciante`, `chave_andar`
- skills (exemplos): `warrior_golpe_brutal`, `archer_tiro_preciso`, `mage_bola_de_fogo`
- pet futuro: `slime_pet`
