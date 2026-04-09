class_name CharacterClassData
extends Resource

@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String

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

func is_config_valid() -> bool:
    return not id.is_empty() and not display_name.is_empty()

