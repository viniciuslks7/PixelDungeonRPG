extends Control

const GAME_SCENE_PATH := "res://scenes/main/main.tscn"
const CLASS_IDS: Array[StringName] = [&"warrior", &"archer", &"mage"]
const CLASS_LABELS: Array[String] = ["Guerreiro", "Arqueiro", "Mago"]

@onready var _play_button: Button = $CenterContainer/Panel/Margin/VBox/PlayButton
@onready var _camp_button: Button = $CenterContainer/Panel/Margin/VBox/CampButton
@onready var _quit_button: Button = $CenterContainer/Panel/Margin/VBox/QuitButton
@onready var _class_selector: OptionButton = $CenterContainer/Panel/Margin/VBox/ClassPicker/ClassSelector

func _ready() -> void:
    _play_button.pressed.connect(_on_play_button_pressed)
    _camp_button.pressed.connect(_on_camp_button_pressed)
    _quit_button.pressed.connect(_on_quit_button_pressed)
    _setup_class_selector()
    _play_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_accept"):
        _on_play_button_pressed()
        return

    if event.is_action_pressed("ui_cancel"):
        _on_quit_button_pressed()
        return

    if event is not InputEventKey:
        return

    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return

    if key_event.physical_keycode == KEY_ENTER or key_event.physical_keycode == KEY_KP_ENTER:
        _on_play_button_pressed()
    elif key_event.physical_keycode == KEY_ESCAPE:
        _on_quit_button_pressed()

func _on_play_button_pressed() -> void:
    _sync_selected_class()
    var scene_manager: Node = _get_scene_manager()
    if scene_manager != null and scene_manager.has_method("change_scene"):
        scene_manager.call("change_scene", GAME_SCENE_PATH)
        return

    var error: Error = get_tree().change_scene_to_file(GAME_SCENE_PATH)
    if error != OK:
        push_error("Falha ao iniciar o jogo. Nao foi possivel abrir %s (erro: %d)." % [GAME_SCENE_PATH, error])

func _on_camp_button_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/base_camp_screen.tscn")

func _on_quit_button_pressed() -> void:
    get_tree().quit()

func _setup_class_selector() -> void:
    _class_selector.clear()
    for index in range(CLASS_IDS.size()):
        _class_selector.add_item(CLASS_LABELS[index], index)
        _class_selector.set_item_metadata(index, CLASS_IDS[index])
    _class_selector.item_selected.connect(_on_class_selected)

    var game_manager: Node = _get_game_manager()
    var selected_class_id: StringName = &"warrior"
    if game_manager != null:
        selected_class_id = game_manager.get("selected_class_id") as StringName

    var initial_index: int = _index_of_class_id(selected_class_id)
    _class_selector.select(initial_index)
    _sync_selected_class()

func _on_class_selected(_index: int) -> void:
    _sync_selected_class()

func _sync_selected_class() -> void:
    var selected_index: int = _class_selector.get_selected()
    if selected_index < 0:
        return
    var selected_class_id := _class_selector.get_item_metadata(selected_index) as StringName
    if selected_class_id.is_empty():
        return

    var game_manager: Node = _get_game_manager()
    if game_manager != null and game_manager.has_method("set_selected_class"):
        game_manager.call("set_selected_class", selected_class_id)

func _index_of_class_id(class_id: StringName) -> int:
    for index in range(CLASS_IDS.size()):
        if CLASS_IDS[index] == class_id:
            return index
    return 0

func _get_scene_manager() -> Node:
    return get_node_or_null("/root/SceneManager")

func _get_game_manager() -> Node:
    return get_node_or_null("/root/GameManager")
