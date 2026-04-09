extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")

var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _run() -> void:
    var main := MAIN_SCENE.instantiate()
    add_child(main)
    await get_tree().process_frame

    var player: Node = main.get("_player")
    var enemy: Node = main.get("_enemy")
    var room: Node = main.get("_current_room")

    _expect(player != null, "Player should spawn.")
    _expect(enemy != null, "Enemy should spawn.")
    _expect(room != null, "Room should spawn.")

    if _failures.is_empty():
        _expect(player.get_grid_position() == room.player_spawn_cell, "Player should start at room spawn cell.")
        _expect(enemy.get_grid_position() == room.enemy_spawn_cell, "Enemy should start at enemy spawn cell.")
        _expect(main._is_cell_blocked(room.enemy_spawn_cell), "Enemy cell should block player movement.")
        _expect(not main._try_player_melee_attack(), "Player should not hit an enemy from non-adjacent cells.")

        player.set_grid_position(room.enemy_spawn_cell + Vector2i.LEFT)
        _expect(main._try_player_melee_attack(), "First adjacent attack should hit enemy.")
        _expect(enemy.health.current_health == 4, "Enemy should have 4 HP after first hit.")
        _expect(main._try_player_melee_attack(), "Second adjacent attack should hit enemy.")

        await get_tree().process_frame
        _expect(not is_instance_valid(enemy), "Enemy should be freed after lethal damage.")

    main.queue_free()
    await get_tree().process_frame

    if _failures.is_empty():
        print("VALIDATION PASSED: core loop attack dummy")
        get_tree().quit(0)
        return

    for failure in _failures:
        push_error(failure)

    get_tree().quit(1)

func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)
