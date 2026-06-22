extends Node2D

var wave_start_time: float = 0.0
var starting_player_health: float = 100.0
var wave_activated: bool = false

@onready var enemy_blueprint = preload("res://entities/enemy/enemy_base.tscn")
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var roulette_layer = $RouletteWheelUI

func _ready() -> void:
	wave_start_time = Time.get_ticks_msec() / 1000.0
	spawn_enemy_wave()
	
	# Wait one frame for engine node registrations to finalize
	await get_tree().process_frame
	wave_activated = true

func spawn_enemy_wave() -> void:
	# Determine scale: Wave 1 = 2 enemies, Wave 2 = 4 enemies, Wave 3 = 6 enemies...
	var spawn_count = Global.current_wave * 2
	print("[SPAWNER]: Initializing Wave Layout. Spawning ", spawn_count, " mobsters.")
	
	for i in range(spawn_count):
		var enemy_instance = enemy_blueprint.instantiate() as CharacterBody2D
		add_child(enemy_instance)
		
		# Stagger their starting horizontal positioning slightly so they don't stack perfectly
		enemy_instance.global_position = spawn_point.global_position + Vector2(i * 40, 0)

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
