class_name MonsterData
extends Resource

enum BehaviorType {
    PASSIVE,
    CHASER,
    SKIRMISHER,
    RANGED,
    ELITE,
    BOSS,
}

@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String

@export_group("Visual")
@export var idle_sprite: Texture2D

@export_group("Combat")
@export var level: int = 1
@export var max_health: int = 10
@export var attack: int = 2
@export var defense: int = 0
@export var speed: int = 3
@export var melee_range: int = 1

@export_group("Behavior")
@export var behavior: BehaviorType = BehaviorType.CHASER
@export var can_open_doors: bool = false
@export var tags: Array[StringName] = []

@export_group("Rewards")
@export var xp_reward: int = 5
@export var loot_table_id: StringName

func is_elite() -> bool:
    return behavior == BehaviorType.ELITE or behavior == BehaviorType.BOSS
