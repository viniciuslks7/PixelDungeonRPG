extends Control

const GAME_SCENE_PATH := "res://scenes/main/main.tscn"

@onready var _restart_button: Button = $CenterContainer/Panel/Margin/VBox/RestartButton
@onready var _floor_label: Label = $CenterContainer/Panel/Margin/VBox/FloorLabel

func _ready() -> void:
    _restart_button.pressed.connect(_on_restart_pressed)
    _restart_button.grab_focus()
    _floor_label.text = "Andar concluido: %d" % maxi(GameManager.current_floor, 1)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        _on_restart_pressed()

func _on_restart_pressed() -> void:
    GameManager.state = GameManager.State.BOOT
    var scene_manager: Node = get_node_or_null("/root/SceneManager")
    if scene_manager != null and scene_manager.has_method("change_scene"):
        scene_manager.call("change_scene", GAME_SCENE_PATH)
        return

    get_tree().change_scene_to_file(GAME_SCENE_PATH)
