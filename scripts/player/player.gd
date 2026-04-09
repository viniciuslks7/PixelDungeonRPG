class_name Player
extends Node2D

signal action_animation_finished

@export var attack_power: int = 4

@onready var grid_movement := $GridMovement
@onready var health := $Health

func _ready() -> void:
    grid_movement.move_finished.connect(_on_move_finished)
    health.health_changed.connect(_on_health_changed)
    health.died.connect(_on_died)

func set_grid_position(cell: Vector2i) -> void:
    grid_movement.grid_position = cell
    grid_movement.snap_to_grid()

func get_grid_position() -> Vector2i:
    return grid_movement.grid_position

func try_move_direction(direction: Vector2i, is_cell_blocked: Callable) -> bool:
    return grid_movement.try_move(direction, is_cell_blocked)

func is_alive() -> bool:
    return health.current_health > 0

func take_damage(amount: int) -> int:
    var applied_damage: int = health.take_damage(amount)
    if applied_damage > 0:
        EventBus.actor_damaged.emit(name, applied_damage, health.current_health, health.max_health)
    return applied_damage

func try_attack(target: Node) -> bool:
    if target == null or not target.has_method("take_damage"):
        return false

    var applied_damage: int = target.take_damage(attack_power)
    if applied_damage <= 0:
        return false

    EventBus.actor_attacked.emit(name, target.name, applied_damage)
    EventBus.action_resolved.emit(name, &"attack")
    action_animation_finished.emit()
    return true

func _on_move_finished(_new_cell: Vector2i) -> void:
    EventBus.action_resolved.emit(name, &"move")
    action_animation_finished.emit()

func _on_health_changed(current_health: int, max_health: int) -> void:
    EventBus.player_health_changed.emit(current_health, max_health)

func _on_died() -> void:
    EventBus.player_died.emit()
