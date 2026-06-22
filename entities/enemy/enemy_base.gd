# res://entities/enemies/enemy_base.gd
extends CharacterBody2D

# Added DEAD state to handle interception cleanups cleanly
enum State { STALKING, TELL, STRIKING, COOLDOWN, DEAD }

@export var speed: float = 120.0
@export var attack_range: float = 45.0
@export var tell_duration: float = 0.6
@export var cooldown_duration: float = 1.2

@onready var counter_indicator: ColorRect = $CounterIndicator

var current_state: State = State.STALKING
var player: CharacterBody2D = null

var tell_timer: float = 0.0
var cooldown_timer: float = 0.0
var flash_timer: float = 0.0

func _ready() -> void:
	counter_indicator.visible = false
	find_player_target()
	
	# Wire up the health component so normal weapon attacks can also trigger death
	var health_node = get_node_or_null("HealthComponent") as HealthComponent
	if health_node:
		health_node.entity_died.connect(die)

func _physics_process(delta: float) -> void:
	# Ignore all movement and combat tracking loops if dead
	if current_state == State.DEAD:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if not player or not is_instance_valid(player):
		find_player_target()
		velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()
		return

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

func handle_stalking_state() -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= attack_range:
		current_state = State.TELL
		tell_timer = tell_duration
		velocity.x = 0
		print("[ENEMY STATE]: Target acquired. Shifting to TELL. Counter window is OPEN.")
		return
		
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * speed

func handle_tell_state(delta: float) -> void:
	velocity.x = 0
	tell_timer -= delta
	
	flash_timer += delta
	if flash_timer >= 0.07:
		counter_indicator.visible = not counter_indicator.visible
		flash_timer = 0.0
	
	if tell_timer <= 0.0:
		current_state = State.STRIKING

func handle_striking_state() -> void:
	counter_indicator.visible = false
	print("[ENEMY STATE]: Flash window CLOSED. Executing strike payload.")
	
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= attack_range + 10.0:
		var player_health = player.get_node_or_null("HealthComponent") as HealthComponent
		if player_health:
			player_health.damage(10.0)
			
	current_state = State.COOLDOWN
	cooldown_timer = cooldown_duration

func handle_cooldown_state(delta: float) -> void:
	velocity.x = 0
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		current_state = State.STALKING

func find_player_target() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

# Exposes a safety check for the player to read during a counter attempt
func is_counterable() -> bool:
	return current_state == State.TELL

# Triggered by a successful player parry input
func get_countered() -> void:
	print("Combat Log: Enemy counter window intercepted successfully!")
	die()

# Handles visual breakdown, turns off active body collisions, and cleans up memory
func die() -> void:
	if current_state == State.DEAD:
		return
		
	current_state = State.DEAD
	velocity = Vector2.ZERO
	counter_indicator.visible = false
	
	# Turn off collisions instantly so the player doesn't get blocked by a corpse
	$CollisionShape2D.set_deferred("disabled", true)
	var hitbox = get_node_or_null("HitboxComponent") as Area2D
	if hitbox:
		hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
		
	# Greybox Procedural Death Animation: Spin fast, change color to black-crimson, shrink to nothing
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", 6.28 * 2, 0.25) # Two full 360-degree rotations
	
	# Safely delete node when the tween finishes running
	tween.chain().tween_callback(queue_free)
