extends Node

const MAX_FLOOR: int = 80

var _floor_data_by_level: Dictionary = {}

func _ready() -> void:
    _build_floor_data()

func get_floor_data(floor_level: int) -> Dictionary:
    var clamped_floor: int = clampi(floor_level, 1, MAX_FLOOR)
    return _floor_data_by_level.get(clamped_floor, _floor_data_by_level.get(1, {})).duplicate(true)

func get_max_floor() -> int:
    return MAX_FLOOR

func _build_floor_data() -> void:
    _floor_data_by_level.clear()

    for floor_level in range(1, MAX_FLOOR + 1):
        var variant: int = (floor_level - 1) % 4
        var path: Array[Vector2i] = _build_path_for_variant(variant)
        var enemy_cells: Array[Vector2i] = _build_enemy_cells_for_variant(variant)
        var chest_cell: Vector2i = _build_chest_cell_for_variant(variant)
        var stage_block: int = int((floor_level - 1) / 20)
        var multipliers: Dictionary = _calculate_stage_multipliers(floor_level, stage_block)

        _floor_data_by_level[floor_level] = {
            "floor_level": floor_level,
            "path": path,
            "player_spawn_cell": path[0] if not path.is_empty() else Vector2i(2, 2),
            "enemy_cells": enemy_cells,
            "props": _build_props_for_variant(variant),
            "chest_cell": chest_cell,
            "enemy_health_multiplier": float(multipliers.get("health", 1.0)),
            "enemy_attack_multiplier": float(multipliers.get("attack", 1.0)),
            "elite_chance": float(multipliers.get("elite_chance", 0.0)),
            "chest_tier": 1 + stage_block,
            "danger_score": int(multipliers.get("danger_score", 100)),
        }

func _calculate_stage_multipliers(floor_level: int, stage_block: int) -> Dictionary:
    var stage_index: int = clampi(stage_block, 0, 3)
    var local_index: int = (floor_level - 1) % 20

    var health_base: Array[float] = [1.0, 1.55, 2.45, 3.70]
    var health_step: Array[float] = [0.025, 0.04, 0.055, 0.075]
    var attack_base: Array[float] = [1.0, 1.35, 1.95, 2.85]
    var attack_step: Array[float] = [0.018, 0.028, 0.04, 0.055]
    var elite_base: Array[float] = [0.0, 0.04, 0.1, 0.18]
    var elite_step: Array[float] = [0.0, 0.002, 0.003, 0.004]

    var health_multiplier: float = health_base[stage_index] + float(local_index) * health_step[stage_index]
    var attack_multiplier: float = attack_base[stage_index] + float(local_index) * attack_step[stage_index]
    var elite_chance: float = elite_base[stage_index] + float(local_index) * elite_step[stage_index]
    var danger_score: int = int(round((health_multiplier * 85.0) + (attack_multiplier * 95.0) + float(floor_level) * 4.0))

    return {
        "health": health_multiplier,
        "attack": attack_multiplier,
        "elite_chance": minf(elite_chance, 0.35),
        "danger_score": danger_score,
    }

func _build_path_for_variant(variant: int) -> Array[Vector2i]:
    match variant:
        0:
            return [
                Vector2i(2, 2), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3),
                Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3), Vector2i(9, 3), Vector2i(9, 4),
                Vector2i(9, 5), Vector2i(8, 5), Vector2i(7, 5), Vector2i(6, 5), Vector2i(5, 5),
                Vector2i(4, 5), Vector2i(3, 5), Vector2i(2, 5), Vector2i(2, 6),
            ]
        1:
            return [
                Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2),
                Vector2i(7, 2), Vector2i(8, 2), Vector2i(9, 2), Vector2i(9, 3), Vector2i(8, 3),
                Vector2i(7, 3), Vector2i(6, 3), Vector2i(5, 3), Vector2i(4, 3), Vector2i(3, 3),
                Vector2i(2, 3), Vector2i(2, 4), Vector2i(2, 5), Vector2i(2, 6),
            ]
        2:
            return [
                Vector2i(2, 2), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3),
                Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3), Vector2i(9, 3), Vector2i(9, 4),
                Vector2i(9, 5), Vector2i(8, 5), Vector2i(7, 5), Vector2i(6, 5), Vector2i(5, 5),
                Vector2i(4, 5), Vector2i(3, 5), Vector2i(2, 5), Vector2i(2, 6),
            ]
        _:
            return [
                Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2),
                Vector2i(7, 2), Vector2i(8, 2), Vector2i(8, 3), Vector2i(8, 4), Vector2i(9, 4),
                Vector2i(9, 5), Vector2i(8, 5), Vector2i(7, 5), Vector2i(6, 5), Vector2i(5, 5),
                Vector2i(4, 5), Vector2i(3, 5), Vector2i(2, 5), Vector2i(2, 6),
            ]

func _build_enemy_cells_for_variant(variant: int) -> Array[Vector2i]:
    match variant:
        0:
            return [Vector2i(5, 2), Vector2i(9, 2), Vector2i(2, 6)]
        1:
            return [Vector2i(6, 2), Vector2i(9, 3), Vector2i(2, 5)]
        2:
            return [Vector2i(4, 3), Vector2i(8, 3), Vector2i(2, 6)]
        _:
            return [Vector2i(5, 3), Vector2i(9, 4), Vector2i(3, 5)]

func _build_chest_cell_for_variant(variant: int) -> Vector2i:
    match variant:
        0:
            return Vector2i(3, 6)
        1:
            return Vector2i(3, 6)
        2:
            return Vector2i(9, 6)
        _:
            return Vector2i(8, 6)

func _build_props_for_variant(variant: int) -> Array[Dictionary]:
    match variant:
        0:
            return [
                {"cell": Vector2i(1, 2), "type": "torch"},
                {"cell": Vector2i(10, 5), "type": "torch"},
                {"cell": Vector2i(6, 6), "type": "altar"},
                {"cell": Vector2i(1, 6), "type": "stairs"},
            ]
        1:
            return [
                {"cell": Vector2i(1, 1), "type": "torch"},
                {"cell": Vector2i(10, 2), "type": "torch"},
                {"cell": Vector2i(6, 6), "type": "altar"},
                {"cell": Vector2i(10, 6), "type": "stairs"},
            ]
        2:
            return [
                {"cell": Vector2i(1, 3), "type": "torch"},
                {"cell": Vector2i(10, 4), "type": "torch"},
                {"cell": Vector2i(6, 6), "type": "altar"},
                {"cell": Vector2i(9, 1), "type": "stairs"},
            ]
        _:
            return [
                {"cell": Vector2i(2, 1), "type": "torch"},
                {"cell": Vector2i(10, 4), "type": "torch"},
                {"cell": Vector2i(6, 6), "type": "altar"},
                {"cell": Vector2i(8, 1), "type": "stairs"},
            ]
