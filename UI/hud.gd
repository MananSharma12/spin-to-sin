extends CanvasLayer

@onready var health_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	# Use call_deferred to give the player node a microsecond to spawn completely first
	call_deferred("initialize_health_binding")

func initialize_health_binding() -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	if player:
		# Fetch the HealthComponent node inside the player's tree structure
		var health_node = player.get_node_or_null("HealthComponent") as HealthComponent
		
		if health_node:
			# 1. Establish structural limits based on actual component values
			health_bar.max_value = health_node.max_health
			health_bar.value = health_node.current_health
			
			# 2. Connect the runtime signal to our local update handler
			health_node.health_altered.connect(_on_player_health_altered)
			print("HUD successfully bound to Player HealthComponent.")
		else:
			print("Error: HUD found Player, but missing 'HealthComponent' child node.")
	else:
		print("Error: HUD initialization failed. No 'player' group node found in scene tree.")

func _on_player_health_altered(new_value: float) -> void:
	# Smoothly set the value of the progress bar UI slider element
	health_bar.value = new_value
