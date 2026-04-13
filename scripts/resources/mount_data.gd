class_name MountData
extends Resource

enum MountRole {
    SPEED,
    OFFENSE,
    DEFENSE,
    BALANCED,
}

@export var id: StringName
@export var display_name: StringName
@export_multiline var description: String
@export var icon: Texture2D
@export_group("Visual")
@export var idle_sprite: Texture2D
@export var run_sprite: Texture2D

@export_group("Bonuses")
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var health_bonus: int = 0
@export var movement_speed_bonus: int = 0

@export_group("Role")
@export var mount_role: MountRole = MountRole.BALANCED
@export var unlock_item_id: StringName
