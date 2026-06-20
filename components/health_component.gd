extends Node
class_name HealthComponent

signal entity_died
signal health_altered(new_value)

@export var max_health: float = 100.0
@onready var current_health: float = max_health

func damage(amount: float):
	current_health = clamp(current_health - amount, 0, max_health)
	health_altered.emit(current_health)
	if current_health <= 0:
		entity_died.emit()
