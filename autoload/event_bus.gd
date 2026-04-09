extends Node

signal bootstrap_completed
signal player_spawned(player: Node2D)
signal player_turn_ready
signal player_health_changed(current_health: int, max_health: int)
signal player_died
signal turn_phase_changed(previous_phase: int, new_phase: int, turn_number: int)
signal actor_moved(actor_name: String, from_cell: Vector2i, to_cell: Vector2i)
signal actor_attacked(attacker_name: String, target_name: String, damage: int)
signal actor_damaged(actor_name: String, amount: int, current_health: int, max_health: int)
signal actor_died(actor_name: String)
signal action_resolved(actor_name: String, action_name: StringName)
