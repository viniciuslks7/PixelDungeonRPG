class_name WorldItem
extends Node2D

@export var item_data: ItemData:
    set(value):
        item_data = value
        if is_inside_tree():
            queue_redraw()
@export var quantity: int = 1
@export var cell_size: int = 32

var _grid_position: Vector2i = Vector2i.ZERO

const ITEM_COLOR_COMMON := Color(0.89, 0.84, 0.36, 1.0)
const ITEM_COLOR_UNCOMMON := Color(0.45, 0.85, 0.45, 1.0)
const ITEM_COLOR_RARE := Color(0.37, 0.62, 0.95, 1.0)
const ITEM_COLOR_EPIC := Color(0.74, 0.42, 0.93, 1.0)
const ITEM_COLOR_LEGENDARY := Color(0.96, 0.56, 0.21, 1.0)

func _ready() -> void:
    _snap_to_grid()
    queue_redraw()

func set_grid_position(cell: Vector2i, world_cell_size: int = 32) -> void:
    _grid_position = cell
    cell_size = world_cell_size
    _snap_to_grid()

func get_grid_position() -> Vector2i:
    return _grid_position

func pickup(receiver: Node) -> bool:
    if receiver == null or not receiver.has_method("add_item"):
        return false
    if item_data == null or quantity <= 0:
        return false

    var added: bool = receiver.add_item(item_data, quantity)
    if not added:
        return false

    var actor_name: String = receiver.display_name if "display_name" in receiver else receiver.name
    EventBus.item_picked_up.emit(actor_name, item_data.display_name, quantity)
    queue_free()
    return true

func _draw() -> void:
    var center := Vector2(cell_size * 0.5, cell_size * 0.5)
    var radius := float(cell_size) * 0.2
    draw_circle(center, radius, _get_draw_color())
    draw_circle(center, radius * 0.55, Color(0.1, 0.1, 0.1, 0.35))

func _get_draw_color() -> Color:
    if item_data == null:
        return ITEM_COLOR_COMMON

    match item_data.rarity:
        ItemData.Rarity.UNCOMMON:
            return ITEM_COLOR_UNCOMMON
        ItemData.Rarity.RARE:
            return ITEM_COLOR_RARE
        ItemData.Rarity.EPIC:
            return ITEM_COLOR_EPIC
        ItemData.Rarity.LEGENDARY:
            return ITEM_COLOR_LEGENDARY
        _:
            return ITEM_COLOR_COMMON

func _snap_to_grid() -> void:
    position = Vector2(_grid_position.x * cell_size, _grid_position.y * cell_size)
