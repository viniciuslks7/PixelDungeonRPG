class_name TestRoom
extends Node2D

@export var cell_size: int = 32
@export var room_size: Vector2i = Vector2i(12, 8)
@export var player_spawn_cell: Vector2i = Vector2i(2, 2)
@export var enemy_spawn_cells: Array[Vector2i] = [
    Vector2i(5, 2),
    Vector2i(9, 2),
    Vector2i(2, 6),
]
@export var item_spawn_cells: Array[Vector2i] = [
    Vector2i(2, 3),
    Vector2i(3, 3),
]
@export var blocked_cells: Array[Vector2i] = [
    Vector2i(4, 4),
    Vector2i(5, 4),
    Vector2i(6, 4),
]

const FLOOR_TEXTURE_PATH := "res://assets/world/dungeon/tile_floor.svg"
const WALL_TEXTURE_PATH := "res://assets/world/dungeon/tile_wall.svg"
const GRID_COLOR := Color(0.24, 0.24, 0.28, 1.0)
const FLOOR_FALLBACK_A := Color(0.12, 0.12, 0.15, 1.0)
const FLOOR_FALLBACK_B := Color(0.16, 0.16, 0.19, 1.0)
const WALL_FALLBACK_A := Color(0.23, 0.23, 0.28, 1.0)
const WALL_FALLBACK_B := Color(0.28, 0.28, 0.33, 1.0)
const BLOCK_OVERLAY_COLOR := Color(0.62, 0.22, 0.22, 0.45)
const BLOCK_EDGE_COLOR := Color(0.82, 0.46, 0.46, 0.95)
const ITEM_MARKER_COLOR := Color(0.95, 0.78, 0.22, 0.95)

var _floor_texture: Texture2D
var _wall_texture: Texture2D

func _ready() -> void:
    _floor_texture = load(FLOOR_TEXTURE_PATH) as Texture2D
    _wall_texture = load(WALL_TEXTURE_PATH) as Texture2D
    queue_redraw()

func is_cell_blocked(cell: Vector2i) -> bool:
    if cell.x < 0 or cell.y < 0:
        return true
    if cell.x >= room_size.x or cell.y >= room_size.y:
        return true
    return cell in blocked_cells

func _draw() -> void:
    for y in range(room_size.y):
        for x in range(room_size.x):
            var cell := Vector2i(x, y)
            var cell_rect := Rect2(
                Vector2(x * cell_size, y * cell_size),
                Vector2(cell_size, cell_size)
            )

            if cell in blocked_cells:
                _draw_cell_fill(cell_rect, cell, _wall_texture, WALL_FALLBACK_A, WALL_FALLBACK_B)
                draw_rect(cell_rect, BLOCK_OVERLAY_COLOR, true)
                draw_rect(cell_rect, BLOCK_EDGE_COLOR, false, 2.0)
            else:
                _draw_cell_fill(cell_rect, cell, _floor_texture, FLOOR_FALLBACK_A, FLOOR_FALLBACK_B)

            if cell in item_spawn_cells:
                var marker_size := Vector2(cell_size * 0.36, cell_size * 0.36)
                var marker_pos := cell_rect.position + (cell_rect.size - marker_size) * 0.5
                draw_rect(Rect2(marker_pos, marker_size), ITEM_MARKER_COLOR, true)

            draw_rect(cell_rect, GRID_COLOR, false, 1.0)

func _draw_cell_fill(
    cell_rect: Rect2,
    cell: Vector2i,
    texture: Texture2D,
    fallback_a: Color,
    fallback_b: Color
) -> void:
    if texture != null:
        draw_texture_rect(texture, cell_rect, false)
        return

    var use_first_color: bool = ((cell.x + cell.y) % 2) == 0
    draw_rect(cell_rect, fallback_a if use_first_color else fallback_b, true)
