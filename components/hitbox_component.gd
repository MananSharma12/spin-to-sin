extends Area2D
class_name HitboxComponent

@export var health_node: HealthComponent

func take_impact(damage_value: float):
	if health_node:
		health_node.damage(damage_value)	
