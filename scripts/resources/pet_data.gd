class_name PetData
extends Resource

enum PetRole {
    FOLLOWER,
    TANK,
    DPS,
    SUPPORT,
    LOOTER,
}

@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String
@export var icon: Texture2D
@export_group("Visual")
@export var idle_sprite: Texture2D
@export var walk_sprite: Texture2D
@export var attack_sprite: Texture2D

@export_group("Combat")
@export var max_health: int = 8
@export var attack: int = 1
@export var defense: int = 0
@export var speed: int = 4

@export_group("Role")
@export var pet_role: PetRole = PetRole.FOLLOWER
@export var unlock_item_id: StringName
@export var passive_bonus_description: String = ""
@export var tags: Array[StringName] = []

@export_group("Bonuses")
@export var passive_attack_bonus: int = 0
@export var passive_defense_bonus: int = 0
@export var passive_health_bonus: int = 0

func is_support_pet() -> bool:
    return pet_role == PetRole.SUPPORT or pet_role == PetRole.LOOTER
