class_name Enemy
extends Node2D

@export var display_name: StringName = &"Dummy"
@export var attack_power: int = 1

@onready var grid_movement := $GridMovement
@onready var health := $Health

func _ready() -> void:
    health.died.connect(_on_died)

func set_grid_position(cell: Vector2i) -> void:
    grid_movement.grid_position = cell
    grid_movement.snap_to_grid()

func get_grid_position() -> Vector2i:
    return grid_movement.grid_position

func is_alive() -> bool:
    return health.current_health > 0

func take_damage(amount: int) -> int:
    var applied_damage: int = health.take_damage(amount)
    if applied_damage > 0:
        EventBus.actor_damaged.emit(name, applied_damage, health.current_health, health.max_health)
    return applied_damage

func _on_died() -> void:
    EventBus.actor_died.emit(name)
    queue_free()
