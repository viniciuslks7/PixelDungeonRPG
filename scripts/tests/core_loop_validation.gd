extends Node

const MAIN_SCENE := preload("res://scenes/main/main.tscn")
const TURN_WAIT_TIMEOUT_SECONDS := 1.5

var _failures: Array[String] = []

func _ready() -> void:
    _run.call_deferred()

func _run() -> void:
    GameManager.set_selected_class(&"warrior")
    var main := MAIN_SCENE.instantiate()
    add_child(main)
    await get_tree().process_frame

    var player: Node = main.get("_player")
    var enemies: Array = main.get("_enemies")
    var room: Node = main.get("_current_room")
    var ground_items: Array = main.get("_ground_items")

    _expect(player != null, "Player should spawn.")
    _expect(enemies.size() == 3, "Three enemies should spawn.")
    _expect(room != null, "Room should spawn.")
    _expect(ground_items.size() == 2, "Two starter items should spawn.")

    if _failures.is_empty():
        _expect(player.get_grid_position() == room.player_spawn_cell, "Player should start at room spawn cell.")
        _expect(enemies[0].get_grid_position() == room.enemy_spawn_cells[0], "Slime should start at the first enemy spawn cell.")
        _expect(enemies[1].get_grid_position() == room.enemy_spawn_cells[1], "Skeleton should start at the second enemy spawn cell.")
        _expect(enemies[2].get_grid_position() == room.enemy_spawn_cells[2], "Bat should start at the third enemy spawn cell.")
        for enemy_spawn_cell in room.enemy_spawn_cells:
            _expect(main._is_cell_blocked(enemy_spawn_cell), "Each enemy cell should block player movement.")
        _expect(not main._try_player_melee_attack(), "Player should not hit an enemy from non-adjacent cells.")

        _expect(TurnManager.begin_resolution(), "Turn manager should accept a movement action.")
        _expect(player.try_move_direction(Vector2i.DOWN, Callable(main, "_is_cell_blocked")), "Player should move in the test room.")

        await _wait_for_player_turn()
        _expect(player.get_grid_position() == room.player_spawn_cell + Vector2i.DOWN, "Player should finish the movement action.")
        _expect(player.get_item_quantity(&"espada_curta") == 1, "Player should collect the short sword on the first move.")
        _expect(player.attack_power == 8, "Attack power should include weapon, passives, pet, and mount bonuses.")
        _expect(player.defense_power == 5, "Defense power should include class passives, pet, and mount bonuses.")
        _expect(player.health.max_health == 31, "Max health should include passive, pet, and mount bonuses.")
        _expect(player.equipped_pet != null, "Player should start with a pet equipped.")
        _expect(player.equipped_mount != null, "Player should start with a mount equipped.")
        _expect(enemies[0].get_grid_position() == room.enemy_spawn_cells[0], "Passive slime should hold position while the player is out of range.")
        _expect(TurnManager.phase == TurnManager.Phase.PLAYER_INPUT, "Turn should return after enemy movement.")

        var slime: Node = enemies[0]
        player.set_grid_position(slime.get_grid_position() + Vector2i.LEFT)
        _expect(TurnManager.begin_resolution(), "Turn manager should accept a player action.")
        _expect(main._try_player_melee_attack(), "First adjacent attack should hit enemy.")

        await _wait_for_player_turn()

        _expect(not is_instance_valid(slime), "Enemy should be freed after lethal damage.")
        _expect(player.health.current_health >= 30, "Player should remain healthy after the opening combat exchange.")

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

func _wait_for_player_turn() -> void:
    var deadline := Time.get_ticks_msec() + int(TURN_WAIT_TIMEOUT_SECONDS * 1000.0)

    while TurnManager.phase != TurnManager.Phase.PLAYER_INPUT and Time.get_ticks_msec() < deadline:
        await get_tree().process_frame

    _expect(TurnManager.phase == TurnManager.Phase.PLAYER_INPUT, "Turn should return after enemy movement.")
