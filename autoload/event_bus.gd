extends Node

signal bootstrap_completed
signal player_spawned(player: Node2D)
signal player_turn_ready
signal player_health_changed(current_health: int, max_health: int)
signal player_power_changed(power_general: int)
signal player_died
signal turn_phase_changed(previous_phase: int, new_phase: int, turn_number: int)
signal actor_moved(actor_name: String, from_cell: Vector2i, to_cell: Vector2i)
signal actor_attacked(attacker_name: String, target_name: String, damage: int, is_critical: bool)
signal actor_damaged(actor_name: String, amount: int, current_health: int, max_health: int, is_critical: bool)
signal actor_died(actor_name: String)
signal action_resolved(actor_name: String, action_name: StringName)
signal skill_used(actor_name: String, skill_id: StringName, skill_name: String)
signal item_picked_up(actor_name: String, item_name: String, quantity: int)
signal item_used(actor_name: String, item_name: String, quantity: int)
signal inventory_changed(actor_name: String, item_id: StringName, quantity: int)
signal equipment_changed(actor_name: String, slot: int, item_id: StringName)
signal pet_changed(actor_name: String, pet_id: StringName)
signal mount_changed(actor_name: String, mount_id: StringName)
signal chest_opened(actor_name: String, floor_level: int, chest_tier: int, item_name: String)
signal level_up(level: int)
