extends Node

const FLOATING_NUMBER_SCENE = preload("res://scenes/ui/floating_number.tscn")

func _ready() -> void:
    EventBus.actor_damaged.connect(_on_actor_damaged)

func _on_actor_damaged(actor_name: String, amount: int, current_health: int, max_health: int, is_critical: bool) -> void:
    if amount <= 0:
        return
        
    var root = get_tree().current_scene
    if root == null:
        return
        
    var actor_node = _find_actor_node(root, actor_name)
    if actor_node != null:
        _spawn_number(actor_node.global_position + Vector2(0, -16), amount, is_critical)

func _find_actor_node(base_node: Node, target_name: String) -> Node:
    # A generic recursive search to find the node by display_name or name
    if base_node.has_method("get_node_or_null"):
        if base_node.name == target_name or (base_node.get("display_name") != null and String(base_node.get("display_name")) == target_name):
            return base_node
            
    for child in base_node.get_children():
        var found = _find_actor_node(child, target_name)
        if found != null:
            return found
    return null

func _spawn_number(pos: Vector2, amount: int, is_critical: bool) -> void:
    var number_instance = FLOATING_NUMBER_SCENE.instantiate()
    number_instance.global_position = pos
    
    var current_scene = get_tree().current_scene
    if current_scene:
        current_scene.add_child(number_instance)
        if number_instance.has_method("setup"):
            number_instance.setup(amount, is_critical)
