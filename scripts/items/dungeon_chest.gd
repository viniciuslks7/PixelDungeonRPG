class_name DungeonChest
extends Node2D

signal opened(chest: DungeonChest)

@export var cell_size: int = 32
@export var chest_tier: int = 1

var _grid_position: Vector2i = Vector2i.ZERO
var _is_open: bool = false

func _ready() -> void:
    _snap_to_grid()
    queue_redraw()

func set_grid_position(cell: Vector2i, world_cell_size: int = 32) -> void:
    _grid_position = cell
    cell_size = world_cell_size
    _snap_to_grid()

func get_grid_position() -> Vector2i:
    return _grid_position

func is_open() -> bool:
    return _is_open

func try_open() -> bool:
    if _is_open:
        return false
    _is_open = true
    queue_redraw()
    opened.emit(self)
    return true

func _draw() -> void:
    var top_color: Color = Color(0.85, 0.58, 0.2, 1.0) if not _is_open else Color(0.62, 0.62, 0.62, 1.0)
    var base_color: Color = Color(0.53, 0.36, 0.16, 1.0) if not _is_open else Color(0.4, 0.4, 0.4, 1.0)
    var chest_rect := Rect2(Vector2(cell_size * 0.2, cell_size * 0.32), Vector2(cell_size * 0.6, cell_size * 0.44))
    var lid_rect := Rect2(Vector2(cell_size * 0.2, cell_size * 0.2), Vector2(cell_size * 0.6, cell_size * 0.18))
    draw_rect(chest_rect, base_color, true)
    draw_rect(lid_rect, top_color, true)

func _snap_to_grid() -> void:
    position = Vector2(_grid_position.x * cell_size, _grid_position.y * cell_size)
