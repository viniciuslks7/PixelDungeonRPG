class_name InventoryComponent
extends Node

signal inventory_changed(item_id: StringName, quantity: int)
signal item_added(item_data: ItemData, amount: int, new_quantity: int)
signal item_consumed(item_data: ItemData, amount: int, remaining_quantity: int)

var _entries: Dictionary = {}

func add_item(item_data: ItemData, amount: int = 1) -> bool:
    if item_data == null or item_data.id.is_empty() or amount <= 0:
        return false

    var item_id: StringName = item_data.id
    var current_quantity: int = get_quantity(item_id)
    var max_allowed: int = max(item_data.max_stack, 1) if item_data.can_stack() else 1
    var next_quantity: int = mini(current_quantity + amount, max_allowed)
    var applied_amount: int = next_quantity - current_quantity

    if applied_amount <= 0:
        return false

    _set_entry(item_data, next_quantity)
    item_added.emit(item_data, applied_amount, next_quantity)
    inventory_changed.emit(item_id, next_quantity)
    return true

func has_item(item_id: StringName, amount: int = 1) -> bool:
    if amount <= 0:
        return true
    return get_quantity(item_id) >= amount

func get_quantity(item_id: StringName) -> int:
    var entry: Dictionary = _entries.get(item_id, {})
    return int(entry.get("quantity", 0))

func get_item_data(item_id: StringName) -> ItemData:
    var entry: Dictionary = _entries.get(item_id, {})
    return entry.get("data", null) as ItemData

func consume_item(item_id: StringName, amount: int = 1) -> ItemData:
    if amount <= 0:
        return null

    var entry: Dictionary = _entries.get(item_id, {})
    if entry.is_empty():
        return null

    var current_quantity: int = int(entry.get("quantity", 0))
    if current_quantity < amount:
        return null

    var item_data: ItemData = entry.get("data", null) as ItemData
    var remaining_quantity: int = current_quantity - amount

    if remaining_quantity > 0:
        entry["quantity"] = remaining_quantity
        _entries[item_id] = entry
    else:
        _entries.erase(item_id)

    if item_data != null:
        item_consumed.emit(item_data, amount, remaining_quantity)
    inventory_changed.emit(item_id, remaining_quantity)
    return item_data

func get_quantities() -> Dictionary:
    var snapshot: Dictionary = {}
    for item_id in _entries.keys():
        snapshot[item_id] = int(_entries[item_id]["quantity"])
    return snapshot

func get_entries() -> Array[Dictionary]:
    var entries: Array[Dictionary] = []
    for item_id in _entries.keys():
        var entry: Dictionary = _entries[item_id]
        entries.append({
            "item_id": item_id,
            "data": entry.get("data", null),
            "quantity": int(entry.get("quantity", 0)),
        })
    return entries

func _set_entry(item_data: ItemData, quantity: int) -> void:
    _entries[item_data.id] = {
        "data": item_data,
        "quantity": quantity,
    }
