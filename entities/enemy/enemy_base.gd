extends CharacterBody2D

enum State { STALKING, TELL, STRIKING, COOLDOWN }

@export var speed: float = 120.0
@export var attack_range: float = 45.0 # Distance in pixels to trigger the attack
@export var tell_duration: float = 0.6 # How long the yellow box flashes before the hit
@export var cooldown_duration: float = 1.2 # Break between attacks

@onready var counter_indicator: ColorRect = $CounterIndicator

var current_state: State = State.STALKING
var player: CharacterBody2D = null

# Timers tracked via delta accumulation to avoid requiring extra scene nodes
var tell_timer: float = 0.0
var cooldown_timer: float = 0.0
var flash_timer: float = 0.0

func _ready() -> void:
	counter_indicator.visible = false
	find_player_target()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Dynamic target acquisition fallback
	if not player or not is_instance_valid(player):
		find_player_target()
		velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()
		return

	# State Machine Processing
	match current_state:
		State.STALKING:
			handle_stalking_state()
			
		State.TELL:
			handle_tell_state(delta)
			
		State.STRIKING:
			handle_striking_state()
			
		State.COOLDOWN:
			handle_cooldown_state(delta)

	move_and_slide()

# --- State Logic Functions ---

func handle_stalking_state() -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# If close enough, halt and trigger the visual wind-up tell
	if distance_to_player <= attack_range:
		current_state = State.TELL
		tell_timer = tell_duration
		velocity.x = 0
		print("Enemy triggered attack tell!")
		return
		
	# Otherwise, continue marching toward the target
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed

func handle_tell_state(delta: float) -> void:
	velocity.x = 0 # Remain completely locked in place during wind-up
	tell_timer -= delta
	
	# Code-driven flashing effect: toggle visibility every 0.07 seconds
	flash_timer += delta
	if flash_timer >= 0.07:
		counter_indicator.visible = not counter_indicator.visible
		flash_timer = 0.0
	
	# Wind-up over! Proceed to deliver the blow
	if tell_timer <= 0.0:
		current_state = State.STRIKING

func handle_striking_state() -> void:
	counter_indicator.visible = false # Turn off indicator now that strike is active
	print("Enemy swung weapon!")
	
	# Check if player is still within range when the strike lands
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= attack_range + 10.0: # Slight grace threshold for tracking
		var player_health = player.get_node_or_null("HealthComponent") as HealthComponent
		if player_health:
			print("Enemy successfully damaged the Player!")
			player_health.damage(10.0) # Deals 10 standard damage to the player pool
			
	# Enter cooldown phase immediately following attack execution
	current_state = State.COOLDOWN
	cooldown_timer = cooldown_duration

func handle_cooldown_state(delta: float) -> void:
	velocity.x = 0
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		current_state = State.STALKING

# --- Helper Utilities ---

func find_player_target() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
