extends Control

const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
const GAME_SCENE_PATH := "res://scenes/main/main.tscn"

@onready var _retry_button: Button = $CenterContainer/Panel/Margin/VBox/RetryButton
@onready var _menu_button: Button = $CenterContainer/Panel/Margin/VBox/MenuButton
@onready var _floor_label: Label = $CenterContainer/Panel/Margin/VBox/FloorLabel
@onready var _power_label: Label = $CenterContainer/Panel/Margin/VBox/PowerLabel

func _ready() -> void:
	_retry_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_retry_button.grab_focus()

	var current_floor: int = maxi(GameManager.current_floor, 1)
	_floor_label.text = "Andar alcancado: %d" % current_floor
	_power_label.text = "Turno final: %d" % TurnManager.turn_number

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_on_retry_pressed()

	if event.is_action_pressed("ui_cancel"):
		_on_menu_pressed()

func _on_retry_pressed() -> void:
	GameManager.state = GameManager.State.BOOT
	var scene_manager: Node = get_node_or_null("/root/SceneManager")
	if scene_manager != null and scene_manager.has_method("change_scene"):
		scene_manager.call("change_scene", GAME_SCENE_PATH)
		return

	get_tree().change_scene_to_file(GAME_SCENE_PATH)

func _on_menu_pressed() -> void:
	GameManager.state = GameManager.State.BOOT
	var scene_manager: Node = get_node_or_null("/root/SceneManager")
	if scene_manager != null and scene_manager.has_method("change_scene"):
		scene_manager.call("change_scene", MAIN_MENU_PATH)
		return

	get_tree().change_scene_to_file(MAIN_MENU_PATH)
