extends Node

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

const ATTRIBUTE_KEYS: Array[StringName] = [
    ATTR_MAX_HEALTH,
    ATTR_ATTACK,
    ATTR_DEFENSE,
    ATTR_DODGE,
    ATTR_CRIT_CHANCE,
    ATTR_CRIT_DAMAGE,
    ATTR_ACCURACY,
    ATTR_ATTACK_SPEED,
    ATTR_MOVE_SPEED,
    ATTR_BLOCK,
    ATTR_PENETRATION,
    ATTR_RESILIENCE,
    ATTR_LIFE_STEAL,
    ATTR_TENACITY,
    ATTR_MAX_MANA,
    ATTR_MANA_REGEN,
    ATTR_COOLDOWN_REDUCTION,
    ATTR_ELEMENTAL_POWER,
    ATTR_ELEMENTAL_RESIST,
    ATTR_LUCK,
]

const DEFAULT_ATTRIBUTE_VALUE: int = 20

func create_default_attributes() -> Dictionary:
    var attributes: Dictionary = {}
    for key in ATTRIBUTE_KEYS:
        attributes[key] = DEFAULT_ATTRIBUTE_VALUE
    return attributes

func sanitize_attributes(raw_attributes: Dictionary) -> Dictionary:
    var attributes := create_default_attributes()
    for key in ATTRIBUTE_KEYS:
        if raw_attributes.has(key):
            attributes[key] = maxi(int(raw_attributes[key]), 0)
    return attributes

func calculate_power_general(raw_attributes: Dictionary) -> int:
    var attributes: Dictionary = sanitize_attributes(raw_attributes)

    var offensive: float = (
        _value(attributes, ATTR_ATTACK) * 2.2
        + _value(attributes, ATTR_CRIT_CHANCE) * 1.4
        + _value(attributes, ATTR_CRIT_DAMAGE) * 1.0
        + _value(attributes, ATTR_ACCURACY) * 1.1
        + _value(attributes, ATTR_ATTACK_SPEED) * 1.3
        + _value(attributes, ATTR_PENETRATION) * 1.0
        + _value(attributes, ATTR_ELEMENTAL_POWER) * 1.2
    )

    var defensive: float = (
        _value(attributes, ATTR_MAX_HEALTH) * 1.8
        + _value(attributes, ATTR_DEFENSE) * 2.0
        + _value(attributes, ATTR_DODGE) * 1.2
        + _value(attributes, ATTR_BLOCK) * 1.2
        + _value(attributes, ATTR_RESILIENCE) * 1.1
        + _value(attributes, ATTR_TENACITY) * 1.0
        + _value(attributes, ATTR_ELEMENTAL_RESIST) * 1.1
    )

    var utility: float = (
        _value(attributes, ATTR_MOVE_SPEED) * 1.0
        + _value(attributes, ATTR_LIFE_STEAL) * 1.2
        + _value(attributes, ATTR_MAX_MANA) * 0.8
        + _value(attributes, ATTR_MANA_REGEN) * 1.2
        + _value(attributes, ATTR_COOLDOWN_REDUCTION) * 1.3
    )

    var progression: float = _value(attributes, ATTR_LUCK) * 1.4

    var weighted_power: float = (
        offensive * 0.35
        + defensive * 0.35
        + utility * 0.20
        + progression * 0.10
    )

    return maxi(int(round(weighted_power)), 1)

func _value(attributes: Dictionary, key: StringName) -> float:
    return float(attributes.get(key, DEFAULT_ATTRIBUTE_VALUE))
