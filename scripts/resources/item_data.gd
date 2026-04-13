class_name ItemData
extends Resource

enum ItemKind {
    CONSUMABLE,
    WEAPON,
    ARMOR,
    KEY_ITEM,
    PET_TOKEN,
}

enum Rarity {
    COMMON,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY,
}

enum EquipSlot {
    NONE,
    HELMET,
    ARMOR,
    GLOVES,
    BOOTS,
    SHIELD,
    WEAPON,
}

@export var id: StringName
var instance_id: StringName = &""
@export var display_name: StringName
@export_multiline var description: String
@export var icon: Texture2D

@export_group("Classification")
@export var item_kind: ItemKind = ItemKind.CONSUMABLE
@export var rarity: Rarity = Rarity.COMMON
@export var tags: Array[StringName] = []

@export_group("Inventory")
@export var stackable: bool = false
@export var max_stack: int = 1

func get_rarity_color() -> Color:
    match rarity:
        Rarity.COMMON: return Color("a8a8a8") # Gray
        Rarity.UNCOMMON: return Color("55ff55") # Green
        Rarity.RARE: return Color("5555ff") # Blue
        Rarity.EPIC: return Color("aa00aa") # Purple
        Rarity.LEGENDARY: return Color("ffaa00") # Orange
    return Color("a8a8a8")

func generate_instance() -> ItemData:
    var instance: ItemData = self.duplicate(true)
    instance.instance_id = StringName("%s_%d" % [id, randi()])
    
    if is_equipment():
        instance.stackable = false
        var multiplier: float = 1.0
        match rarity:
            Rarity.UNCOMMON: multiplier = 1.2
            Rarity.RARE: multiplier = 1.5
            Rarity.EPIC: multiplier = 2.0
            Rarity.LEGENDARY: multiplier = 3.0
            
        instance.attack_bonus = int(instance.attack_bonus * multiplier) + (randi() % 5 if multiplier > 1.0 else 0)
        instance.defense_bonus = int(instance.defense_bonus * multiplier) + (randi() % 3 if multiplier > 1.0 else 0)
    
    return instance

@export_group("Effects")
@export var heal_amount: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var grants_pet_id: StringName

@export_group("Equipment")
@export var equip_slot: EquipSlot = EquipSlot.NONE
@export var allowed_class_ids: Array[StringName] = []

func can_stack() -> bool:
    return stackable and max_stack > 1

func is_equipment() -> bool:
    return item_kind == ItemKind.WEAPON or item_kind == ItemKind.ARMOR

func is_class_allowed(class_id: StringName) -> bool:
    if allowed_class_ids.is_empty():
        return true
    return class_id in allowed_class_ids
