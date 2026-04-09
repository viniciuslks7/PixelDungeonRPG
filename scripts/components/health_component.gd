class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal damaged(amount: int)
signal healed(amount: int)
signal died

@export var max_health: int = 20
@export var current_health: int = 20

func _ready() -> void:
    current_health = clampi(current_health, 0, max_health)
    health_changed.emit(current_health, max_health)

func take_damage(amount: int) -> int:
    if current_health <= 0:
        return 0

    var applied_damage := mini(amount, current_health)
    current_health -= applied_damage
    damaged.emit(applied_damage)
    health_changed.emit(current_health, max_health)

    if current_health == 0:
        died.emit()

    return applied_damage

func heal(amount: int) -> int:
    if current_health >= max_health:
        return 0

    var applied_heal := mini(amount, max_health - current_health)
    current_health += applied_heal
    healed.emit(applied_heal)
    health_changed.emit(current_health, max_health)
    return applied_heal

