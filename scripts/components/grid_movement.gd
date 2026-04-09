class_name GridMovement
extends Node

signal move_started(from_cell: Vector2i, to_cell: Vector2i)
signal move_finished(new_cell: Vector2i)
signal move_blocked(target_cell: Vector2i)

@export var cell_size: int = 32
@export var move_duration: float = 0.08
@export var grid_position: Vector2i = Vector2i.ZERO

var _is_moving: bool = false
var _last_from_cell: Vector2i = Vector2i.ZERO
var _last_to_cell: Vector2i = Vector2i.ZERO

@onready var _actor: Node2D = get_parent() as Node2D

func snap_to_grid() -> void:
    if _actor == null:
        return

    _actor.position = _grid_to_world(grid_position)

func can_accept_input() -> bool:
    return not _is_moving

func try_move(direction: Vector2i, is_cell_blocked: Callable) -> bool:
    if _actor == null or _is_moving or direction == Vector2i.ZERO:
        return false

    var target_cell := grid_position + direction
    if is_cell_blocked.is_valid() and is_cell_blocked.call(target_cell):
        move_blocked.emit(target_cell)
        return false

    _last_from_cell = grid_position
    _last_to_cell = target_cell
    grid_position = target_cell
    _is_moving = true
    move_started.emit(_last_from_cell, target_cell)

    var tween := create_tween()
    tween.tween_property(_actor, "position", _grid_to_world(target_cell), move_duration)
    tween.finished.connect(_on_move_tween_finished, CONNECT_ONE_SHOT)
    return true

func _grid_to_world(cell: Vector2i) -> Vector2:
    return Vector2(cell.x * cell_size, cell.y * cell_size)

func _on_move_tween_finished() -> void:
    _is_moving = false
    if _actor != null:
        EventBus.actor_moved.emit(_actor.name, _last_from_cell, _last_to_cell)
    move_finished.emit(grid_position)
