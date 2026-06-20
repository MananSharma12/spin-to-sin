extends CharacterBody2D

@export var speed: float = 150.0

@onready var counter_indicator: ColorRect = $ColorRect2

var player: CharacterBody2D = null

func _ready() -> void:
	# Initial attempt to locate the player
	find_player_target()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Dynamic Fallback: If player is missing, keep hunting for the group node
	if not player or not is_instance_valid(player):
		find_player_target()
		velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()
		return # Stop executing further tracking tracking logic this frame

	# Horizontal Target Tracking AI
	var direction_to_target = sign(player.global_position.x - global_position.x)
	velocity.x = direction_to_target * speed

	# Execute physics movement
	move_and_slide()

func find_player_target() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
