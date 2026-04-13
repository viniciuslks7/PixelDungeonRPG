class_name CharacterClassData
extends Resource

enum ClassRole {
    TANK,
    RANGED,
    CASTER,
}

const ATTR_MAX_HEALTH: StringName = &"vida_max"
const ATTR_ATTACK: StringName = &"ataque"
const ATTR_DEFENSE: StringName = &"defesa"
const ATTR_DODGE: StringName = &"esquiva"
const ATTR_CRIT_CHANCE: StringName = &"critico_chance"
const ATTR_CRIT_DAMAGE: StringName = &"critico_dano"
const ATTR_ACCURACY: StringName = &"precisao"
const ATTR_ATTACK_SPEED: StringName = &"velocidade_ataque"
const ATTR_MOVE_SPEED: StringName = &"velocidade_movimento"
const ATTR_BLOCK: StringName = &"bloqueio"
const ATTR_PENETRATION: StringName = &"penetracao"
const ATTR_RESILIENCE: StringName = &"resiliencia"
const ATTR_LIFE_STEAL: StringName = &"roubo_vida"
const ATTR_TENACITY: StringName = &"tenacidade"
const ATTR_MAX_MANA: StringName = &"mana_max"
const ATTR_MANA_REGEN: StringName = &"regeneracao_mana"
const ATTR_COOLDOWN_REDUCTION: StringName = &"reducao_recarga"
const ATTR_ELEMENTAL_POWER: StringName = &"poder_elemental"
const ATTR_ELEMENTAL_RESIST: StringName = &"resistencia_elemental"
const ATTR_LUCK: StringName = &"sorte"

@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String

@export_group("Visual")
@export var idle_sprite: Texture2D
@export var walk_sprite: Texture2D
@export var attack_sprite: Texture2D
@export var hit_sprite: Texture2D

@export_group("Role")
@export var role: ClassRole = ClassRole.TANK

@export_group("Base Stats")
@export var base_max_health: int = 20
@export var base_attack: int = 4
@export var base_defense: int = 1
@export var base_speed: int = 4

@export_group("Progression")
@export var health_per_level: int = 4
@export var attack_per_level: int = 1
@export var defense_per_level: int = 1

@export_group("Starting Loadout")
@export var starting_item_ids: Array[StringName] = []

@export_group("Core Attributes")
@export var attr_vida_max: int = 20
@export var attr_ataque: int = 20
@export var attr_defesa: int = 20
@export var attr_esquiva: int = 20
@export var attr_critico_chance: int = 20
@export var attr_critico_dano: int = 20
@export var attr_precisao: int = 20
@export var attr_velocidade_ataque: int = 20
@export var attr_velocidade_movimento: int = 20
@export var attr_bloqueio: int = 20
@export var attr_penetracao: int = 20
@export var attr_resiliencia: int = 20
@export var attr_roubo_vida: int = 20
@export var attr_tenacidade: int = 20
@export var attr_mana_max: int = 20
@export var attr_regeneracao_mana: int = 20
@export var attr_reducao_recarga: int = 20
@export var attr_poder_elemental: int = 20
@export var attr_resistencia_elemental: int = 20
@export var attr_sorte: int = 20

@export_group("Skill Loadout")
@export var active_skill_ids: Array[StringName] = []
@export var passive_skill_ids: Array[StringName] = []

func is_config_valid() -> bool:
    return not id.is_empty() and not display_name.is_empty()

func get_base_attributes() -> Dictionary:
    return {
        ATTR_MAX_HEALTH: attr_vida_max,
        ATTR_ATTACK: attr_ataque,
        ATTR_DEFENSE: attr_defesa,
        ATTR_DODGE: attr_esquiva,
        ATTR_CRIT_CHANCE: attr_critico_chance,
        ATTR_CRIT_DAMAGE: attr_critico_dano,
        ATTR_ACCURACY: attr_precisao,
        ATTR_ATTACK_SPEED: attr_velocidade_ataque,
        ATTR_MOVE_SPEED: attr_velocidade_movimento,
        ATTR_BLOCK: attr_bloqueio,
        ATTR_PENETRATION: attr_penetracao,
        ATTR_RESILIENCE: attr_resiliencia,
        ATTR_LIFE_STEAL: attr_roubo_vida,
        ATTR_TENACITY: attr_tenacidade,
        ATTR_MAX_MANA: attr_mana_max,
        ATTR_MANA_REGEN: attr_regeneracao_mana,
        ATTR_COOLDOWN_REDUCTION: attr_reducao_recarga,
        ATTR_ELEMENTAL_POWER: attr_poder_elemental,
        ATTR_ELEMENTAL_RESIST: attr_resistencia_elemental,
        ATTR_LUCK: attr_sorte,
    }
