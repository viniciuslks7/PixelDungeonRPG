class_name DungeonProp
extends Node2D

enum PropType {
    TORCH,
    ALTAR,
    STAIRS,
}

const PROP_TEXTURE_PATHS := {
    PropType.TORCH: "res://assets/world/dungeon/prop_torch.svg",
    PropType.ALTAR: "res://assets/world/dungeon/prop_altar.svg",
    PropType.STAIRS: "res://assets/world/dungeon/prop_stairs.svg",
}

@export var cell_size: int = 32
@export var prop_type: PropType = PropType.TORCH

var _grid_position: Vector2i = Vector2i.ZERO
var _use_fallback_draw: bool = true

@onready var _sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D

func _ready() -> void:
    _update_visual()

func set_grid_position(cell: Vector2i, world_cell_size: int = 32) -> void:
    _grid_position = cell
    cell_size = world_cell_size
    position = Vector2(_grid_position.x * cell_size, _grid_position.y * cell_size)
    _update_visual()

func _draw() -> void:
    if not _use_fallback_draw:
        return

    match prop_type:
        PropType.TORCH:
            _draw_torch()
        PropType.ALTAR:
            _draw_altar()
        PropType.STAIRS:
            _draw_stairs()

func _update_visual() -> void:
    var texture: Texture2D = _load_texture_for_type(prop_type)
    if _sprite != null and texture != null:
        _sprite.texture = texture
        _sprite.centered = false
        _sprite.position = Vector2.ZERO
        var texture_size: Vector2 = texture.get_size()
        if texture_size.x > 0.0 and texture_size.y > 0.0:
            _sprite.scale = Vector2(float(cell_size) / texture_size.x, float(cell_size) / texture_size.y)
        else:
            _sprite.scale = Vector2.ONE
        _sprite.visible = true
        _use_fallback_draw = false
    else:
        if _sprite != null:
            _sprite.texture = null
            _sprite.scale = Vector2.ONE
            _sprite.visible = false
        _use_fallback_draw = true
    queue_redraw()

func _load_texture_for_type(type: PropType) -> Texture2D:
    var texture_path: String = String(PROP_TEXTURE_PATHS.get(type, ""))
    if texture_path.is_empty():
        return null
    return load(texture_path) as Texture2D

func _draw_torch() -> void:
    var base_rect := Rect2(Vector2(cell_size * 0.44, cell_size * 0.42), Vector2(cell_size * 0.12, cell_size * 0.44))
    draw_rect(base_rect, Color(0.44, 0.28, 0.12, 1.0), true)
    draw_circle(Vector2(cell_size * 0.5, cell_size * 0.32), cell_size * 0.14, Color(1.0, 0.75, 0.28, 0.92))
    draw_circle(Vector2(cell_size * 0.5, cell_size * 0.26), cell_size * 0.08, Color(1.0, 0.93, 0.54, 0.92))

func _draw_altar() -> void:
    var base_rect := Rect2(Vector2(cell_size * 0.18, cell_size * 0.56), Vector2(cell_size * 0.64, cell_size * 0.22))
    draw_rect(base_rect, Color(0.38, 0.38, 0.45, 1.0), true)
    var top_rect := Rect2(Vector2(cell_size * 0.24, cell_size * 0.4), Vector2(cell_size * 0.52, cell_size * 0.2))
    draw_rect(top_rect, Color(0.58, 0.58, 0.68, 1.0), true)
    draw_circle(Vector2(cell_size * 0.5, cell_size * 0.34), cell_size * 0.06, Color(0.44, 0.78, 1.0, 0.95))

func _draw_stairs() -> void:
    for step in range(4):
        var width := cell_size * (0.22 + float(step) * 0.16)
        var height := cell_size * 0.08
        var x := (cell_size - width) * 0.5
        var y := cell_size * (0.34 + float(step) * 0.11)
        var color := Color(0.45 + float(step) * 0.06, 0.45 + float(step) * 0.06, 0.52 + float(step) * 0.05, 1.0)
        draw_rect(Rect2(Vector2(x, y), Vector2(width, height)), color, true)
