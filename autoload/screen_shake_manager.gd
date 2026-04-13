extends Node

@export var max_offset: Vector2 = Vector2(8.0, 8.0)
@export var default_duration: float = 0.2

var _shake_tween: Tween
var _current_camera: Camera2D

func _ready() -> void:
    EventBus.actor_damaged.connect(_on_actor_damaged)

func _on_actor_damaged(_actor_name: String, _amount: int, _current_health: int, _max_health: int, is_critical: bool) -> void:
    if is_critical:
        shake(0.35, 1.5)
    else:
        shake()

func _get_camera() -> Camera2D:
    var viewport = get_viewport()
    if viewport != null:
        return viewport.get_camera_2d()
    return null

func shake(duration: float = default_duration, intensity: float = 1.0) -> void:
    _current_camera = _get_camera()
    if _current_camera == null:
        return

    if _shake_tween and _shake_tween.is_running():
        _shake_tween.kill()

    _shake_tween = create_tween()
    _shake_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

    var current_offset := _current_camera.offset
    var passes := int(duration / 0.05)

    for i in range(passes):
        var random_offset := Vector2(
            randf_range(-max_offset.x, max_offset.x) * intensity,
            randf_range(-max_offset.y, max_offset.y) * intensity
        )
        _shake_tween.tween_property(_current_camera, "offset", random_offset, 0.05)

    _shake_tween.tween_property(_current_camera, "offset", Vector2.ZERO, 0.05)
