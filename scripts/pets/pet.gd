class_name Pet
extends Node2D

@export var pet_data: PetData:
    set(value):
        pet_data = value
        if is_inside_tree():
            _refresh_visual()

@onready var sprite: Sprite2D = $Sprite2D

var _action_sprite_state_id: int = 0

func _ready() -> void:
    _refresh_visual()

func _refresh_visual() -> void:
    if not is_instance_valid(sprite):
        return
    _reset_action_sprite()

func play_walk_animation(duration: float = 0.08) -> void:
    if pet_data == null:
        return
    _set_temporary_action_sprite(pet_data.walk_sprite, duration)

func play_attack_animation(duration: float = 0.08) -> void:
    if pet_data == null:
        return
    _set_temporary_action_sprite(pet_data.attack_sprite, duration)

func _reset_action_sprite() -> void:
    _action_sprite_state_id += 1
    _update_sprite_texture()

func _update_sprite_texture() -> void:
    if not is_instance_valid(sprite) or pet_data == null:
        return

    if pet_data.idle_sprite != null:
        sprite.texture = pet_data.idle_sprite
        return

    if pet_data.icon != null:
        sprite.texture = pet_data.icon

func _set_temporary_action_sprite(action_sprite: Texture2D, duration: float) -> void:
    if action_sprite == null or not is_instance_valid(sprite) or pet_data == null:
        return

    _action_sprite_state_id += 1
    var action_state_id: int = _action_sprite_state_id
    sprite.texture = action_sprite

    var timer := get_tree().create_timer(maxf(duration, 0.0))
    timer.timeout.connect(func() -> void:
        if action_state_id != _action_sprite_state_id:
            return
        _update_sprite_texture()
    )
