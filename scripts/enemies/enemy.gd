class_name Enemy
extends Node2D

signal action_animation_finished

@export var monster_data: MonsterData:
    set(value):
        monster_data = value
        if is_inside_tree():
            _update_from_monster_data()

@export var display_name: StringName = &"Dummy"
@export var attack_power: int = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var grid_movement := $GridMovement
@onready var health := $Health

var _base_sprite_position: Vector2 = Vector2.ZERO
var _base_sprite_scale: Vector2 = Vector2.ONE

func _ready() -> void:
    _base_sprite_position = sprite.position
    _base_sprite_scale = sprite.scale
    _update_from_monster_data()
    grid_movement.move_started.connect(_on_move_started)
    grid_movement.move_finished.connect(_on_move_finished)
    health.died.connect(_on_died)

func _update_from_monster_data() -> void:
    if monster_data:
        display_name = monster_data.display_name
        attack_power = monster_data.attack
        if is_instance_valid(health):
            health.max_health = monster_data.max_health
            health.current_health = monster_data.max_health
    _update_sprite_texture()

func _update_sprite_texture() -> void:
    if not is_instance_valid(sprite):
        return

    if monster_data and monster_data.idle_sprite:
        sprite.texture = monster_data.idle_sprite

func set_grid_position(cell: Vector2i) -> void:
    grid_movement.grid_position = cell
    grid_movement.snap_to_grid()

func get_grid_position() -> Vector2i:
    return grid_movement.grid_position

func is_alive() -> bool:
    return health.current_health > 0

func try_move_direction(direction: Vector2i, is_cell_blocked: Callable) -> bool:
    return grid_movement.try_move(direction, is_cell_blocked)

func take_damage(amount: int, is_critical: bool = false) -> int:
    var applied_damage: int = health.take_damage(amount)
    if applied_damage > 0:
        _play_hit_animation()
        EventBus.actor_damaged.emit(display_name, applied_damage, health.current_health, health.max_health, is_critical)
    return applied_damage

func try_attack(target: Node) -> bool:
    if target == null or not target.has_method("take_damage"):
        return false

    var applied_damage: int = target.take_damage(attack_power, false)
    if applied_damage <= 0:
        return false

    _play_attack_animation()
    var target_name: String = target.display_name if "display_name" in target else target.name
    EventBus.actor_attacked.emit(display_name, target_name, applied_damage, false)
    EventBus.action_resolved.emit(display_name, &"attack")
    action_animation_finished.emit()
    return true

func _on_move_started(_from_cell: Vector2i, _to_cell: Vector2i) -> void:
    _play_walk_animation()

func _on_move_finished(_new_cell: Vector2i) -> void:
    EventBus.action_resolved.emit(display_name, &"move")
    action_animation_finished.emit()

func _on_died() -> void:
    EventBus.actor_died.emit(display_name)
    queue_free()

func _play_walk_animation() -> void:
    _animate_position_bob(_base_sprite_position, Vector2(0.0, -2.0), 0.08)
    _animate_scale_pulse(_base_sprite_scale, Vector2(1.04, 0.96), 0.08)

func _play_attack_animation() -> void:
    _animate_position_bob(_base_sprite_position, Vector2(-2.0, 0.0), 0.08)
    _animate_scale_pulse(_base_sprite_scale, Vector2(1.08, 0.92), 0.08)

func _play_hit_animation() -> void:
    _animate_scale_pulse(_base_sprite_scale, Vector2(0.92, 1.08), 0.06)

func _animate_position_bob(base_position: Vector2, peak_offset: Vector2, duration: float) -> void:
    if not is_instance_valid(sprite):
        return
    sprite.position = base_position
    var tween := create_tween()
    tween.tween_property(sprite, "position", base_position + peak_offset, duration * 0.5)
    tween.tween_property(sprite, "position", base_position, duration * 0.5)

func _animate_scale_pulse(base_scale: Vector2, pulse_scale: Vector2, duration: float) -> void:
    if not is_instance_valid(sprite):
        return
    sprite.scale = base_scale
    var tween := create_tween()
    tween.tween_property(sprite, "scale", Vector2(base_scale.x * pulse_scale.x, base_scale.y * pulse_scale.y), duration * 0.5)
    tween.tween_property(sprite, "scale", base_scale, duration * 0.5)
