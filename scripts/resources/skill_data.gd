class_name SkillData
extends Resource

enum SkillType {
    ACTIVE,
    PASSIVE,
}

enum TargetType {
    NONE,
    SELF,
    ENEMY_FRONT,
}

enum DamageType {
    PHYSICAL,
    FIRE,
    ICE,
    ARCANE,
}

@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String
@export var icon: Texture2D

@export_group("Classification")
@export var skill_type: SkillType = SkillType.ACTIVE
@export var target_type: TargetType = TargetType.ENEMY_FRONT
@export var damage_type: DamageType = DamageType.PHYSICAL

@export_group("Active Runtime")
@export var cooldown_turns: int = 1
@export var mana_cost: int = 0
@export var power_multiplier: float = 1.0
@export var flat_damage_bonus: int = 0
@export var requires_enemy_target: bool = true

@export_group("Passive Bonuses")
@export var passive_attack_bonus: int = 0
@export var passive_defense_bonus: int = 0
@export var passive_health_bonus: int = 0

func is_active() -> bool:
    return skill_type == SkillType.ACTIVE

func is_passive() -> bool:
    return skill_type == SkillType.PASSIVE
