class_name TestRoom
extends Node2D

@export var cell_size: int = 32
@export var room_size: Vector2i = Vector2i(12, 8)
@export var player_spawn_cell: Vector2i = Vector2i(2, 2)
@export var enemy_spawn_cell: Vector2i = Vector2i(5, 2)
@export var blocked_cells: Array[Vector2i] = [
    Vector2i(4, 4),
    Vector2i(5, 4),
    Vector2i(6, 4),
]

const GRID_COLOR := Color(0.24, 0.24, 0.28, 1.0)
const FLOOR_COLOR := Color(0.09, 0.09, 0.11, 1.0)
const BLOCK_COLOR := Color(0.41, 0.17, 0.17, 1.0)

func _ready() -> void:
    queue_redraw()

func is_cell_blocked(cell: Vector2i) -> bool:
    if cell.x < 0 or cell.y < 0:
        return true
    if cell.x >= room_size.x or cell.y >= room_size.y:
        return true
    return cell in blocked_cells

func _draw() -> void:
    var room_rect := Rect2(
        Vector2.ZERO,
        Vector2(room_size.x * cell_size, room_size.y * cell_size)
    )
    draw_rect(room_rect, FLOOR_COLOR, true)

    for y in range(room_size.y):
        for x in range(room_size.x):
            var cell := Vector2i(x, y)
            var cell_rect := Rect2(
                Vector2(x * cell_size, y * cell_size),
                Vector2(cell_size, cell_size)
            )

            if cell in blocked_cells:
                draw_rect(cell_rect, BLOCK_COLOR, true)

            draw_rect(cell_rect, GRID_COLOR, false, 1.0)
