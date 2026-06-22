extends Node2D

var wave_start_time: float = 0.0
var starting_player_health: float = 100.0
var wave_activated: bool = false # The safety latch

@onready var roulette_layer = $RouletteWheelUI

func _ready() -> void:
	wave_start_time = Time.get_ticks_msec() / 1000.0
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var health_node = player.get_node_or_null("HealthComponent") as HealthComponent
		if health_node:
			starting_player_health = health_node.current_health
			
	# CRUCIAL: Wait exactly 1 frame for the engine to fully cache group registries
	await get_tree().process_frame
	
	# Verify that enemies actually exist in the room before arming the win check
	var active_enemies = get_tree().get_nodes_in_group("enemies")
	if active_enemies.size() > 0:
		wave_activated = true
		print("[ARENA STATE]: Wave ", Global.current_wave, " successfully armed. Targets found: ", active_enemies.size())
	else:
		print("[ARENA WARNING]: No enemies found in the 'enemies' group yet! Standing by.")

func _process(_delta: float) -> void:
	if not wave_activated:
		return
		
	var active_enemies = get_tree().get_nodes_in_group("enemies")
	
	AudioManager.update_combat_intensity(active_enemies.size())
	
	if active_enemies.size() == 0:
		wave_activated = false
		set_process(false) 
		execute_wave_clear_sequence()

func execute_wave_clear_sequence() -> void:
	var total_elapsed_time = (Time.get_ticks_msec() / 1000.0) - wave_start_time
	var health_lost: float = 0.0
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var health_node = player.get_node_or_null("HealthComponent") as HealthComponent
		if health_node:
			health_lost = starting_player_health - health_node.current_health
	
	Global.process_wave_performance(total_elapsed_time, health_lost)
	
	if roulette_layer:
		roulette_layer.trigger_wheel_sequence()
	else:
		print("Critical Error: Arena cannot find RouletteWheelUI node instance.")
