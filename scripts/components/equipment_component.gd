class_name EquipmentComponent
extends Node

signal equipment_changed(slot: int, item_data: ItemData)

var _equipped_by_slot: Dictionary = {}

func equip(item_data: ItemData, class_id: StringName) -> bool:
    if not can_equip(item_data, class_id):
        return false

    _equipped_by_slot[item_data.equip_slot] = item_data
    equipment_changed.emit(item_data.equip_slot, item_data)
    return true

func can_equip(item_data: ItemData, class_id: StringName) -> bool:
    if item_data == null:
        return false
    if not item_data.is_equipment():
        return false
    if item_data.equip_slot == ItemData.EquipSlot.NONE:
        return false
    return item_data.is_class_allowed(class_id)

func unequip(slot: int) -> ItemData:
    if not _equipped_by_slot.has(slot):
        return null

    var previous: ItemData = _equipped_by_slot[slot] as ItemData
    _equipped_by_slot.erase(slot)
    equipment_changed.emit(slot, null)
    return previous

func get_equipped(slot: int) -> ItemData:
    return _equipped_by_slot.get(slot, null) as ItemData

func get_equipped_items() -> Array[ItemData]:
    var items: Array[ItemData] = []
    for slot in _equipped_by_slot.keys():
        var item_data: ItemData = _equipped_by_slot[slot] as ItemData
        if item_data != null:
            items.append(item_data)
    return items
