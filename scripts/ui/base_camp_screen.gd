extends Control

@onready var gold_label: Label = $Panel/VBox/Header/GoldLabel
@onready var hp_upgrade_btn: Button = $Panel/VBox/Upgrades/HpContainer/BuyHpButton
@onready var atk_upgrade_btn: Button = $Panel/VBox/Upgrades/AtkContainer/BuyAtkButton
@onready var def_upgrade_btn: Button = $Panel/VBox/Upgrades/DefContainer/BuyDefButton
@onready var back_button: Button = $Panel/VBox/BackButton

var _game_manager: Node

func _ready() -> void:
    _game_manager = get_node_or_null("/root/GameManager")
    back_button.pressed.connect(_on_back_pressed)
    hp_upgrade_btn.pressed.connect(func(): _buy_upgrade("hp_bonus", 50))
    atk_upgrade_btn.pressed.connect(func(): _buy_upgrade("atk_bonus", 100))
    def_upgrade_btn.pressed.connect(func(): _buy_upgrade("def_bonus", 100))
    _refresh_ui()

func _refresh_ui() -> void:
    if _game_manager == null:
        return
        
    var gold: int = _game_manager.get("global_gold")
    gold_label.text = "Ouro Acumulado: %d" % gold
    
    var upgrades: Dictionary = _game_manager.get("account_upgrades")
    hp_upgrade_btn.text = "HP+ (Lvl %d) - 50g" % int(upgrades.get("hp_bonus", 0))
    atk_upgrade_btn.text = "ATK+ (Lvl %d) - 100g" % int(upgrades.get("atk_bonus", 0))
    def_upgrade_btn.text = "DEF+ (Lvl %d) - 100g" % int(upgrades.get("def_bonus", 0))
    
    hp_upgrade_btn.disabled = gold < 50
    atk_upgrade_btn.disabled = gold < 100
    def_upgrade_btn.disabled = gold < 100

func _buy_upgrade(key: String, cost: int) -> void:
    if _game_manager == null:
        return
        
    var gold: int = _game_manager.get("global_gold")
    if gold >= cost:
        _game_manager.set("global_gold", gold - cost)
        var upgrades: Dictionary = _game_manager.get("account_upgrades")
        upgrades[key] = int(upgrades.get(key, 0)) + 1
        _game_manager.save_data()
        _refresh_ui()

func _on_back_pressed() -> void:
    get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
