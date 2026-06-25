extends CharacterBody2D

enum State { STALKING, TELL, STRIKING, COOLDOWN, DEAD }

@export var tier_skin_sheet: Texture2D

@export var speed: float = 120.0
@export var attack_range: float = 45.0
@export var tell_duration: float = 0.6
@export var cooldown_duration: float = 1.2

@onready var counter_indicator: ColorRect = $CounterIndicator
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_state: State = State.STALKING
var player: CharacterBody2D = null

var tell_timer: float = 0.0
var cooldown_timer: float = 0.0
var flash_timer: float = 0.0

var knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	counter_indicator.visible = false
	sprite.play("idle")
	find_player_target()
	
	if tier_skin_sheet:
		pass

	var health_node = get_node_or_null("HealthComponent") as HealthComponent
	if health_node:
		health_node.health_altered.connect(_on_take_damage)
		health_node.entity_died.connect(die)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD: return
	if not is_on_floor(): velocity += get_gravity() * delta

	if not player or not is_instance_valid(player):
		find_player_target()
		velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()
		return

	var direction_to_player = sign(player.global_position.x - global_position.x)
	
	if direction_to_player != 0 and (current_state == State.STALKING or current_state == State.COOLDOWN):
		sprite.flip_h = (direction_to_player < 0)

	match current_state:
		State.STALKING:
			handle_stalking_state(direction_to_player)
		State.TELL:
			handle_tell_state(delta)
		State.STRIKING:
			handle_striking_state()
		State.COOLDOWN:
			handle_cooldown_state(delta)

	if knockback_velocity.length() > 0.1:
		velocity.x = knockback_velocity.x
		knockback_velocity.x = move_toward(knockback_velocity.x, 0, 1200.0 * delta)

	move_and_slide()
func handle_stalking_state(dir: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= attack_range:
		current_state = State.TELL
		tell_timer = tell_duration
		velocity.x = 0
		sprite.play("tell") # Switch to wind-up sprite frame
		return
		
	velocity.x = dir * speed
	sprite.play("run")

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
	
	# FIXING THE MISSING ATTACK FRAME: Code-driven physical lunging juice
	var attack_direction = -1.0 if sprite.flip_h else 1.0
	
	# Tween a sudden snappy stretch-and-thrust motion to simulate a brutal punch
	var launch_tween = create_tween()
	launch_tween.tween_property(sprite, "position:x", attack_direction * 25.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	launch_tween.tween_property(sprite, "position:x", 0.0, 0.15).set_delay(0.08)
	
	# Calculate structural damage payload delivery
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= attack_range + 20.0:
		var player_health = player.get_node_or_null("HealthComponent") as HealthComponent
		if player_health:
			player_health.damage(10.0)
			
	current_state = State.COOLDOWN
	cooldown_timer = cooldown_duration
	sprite.play("idle")

func handle_cooldown_state(delta: float) -> void:
	velocity.x = 0
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		current_state = State.STALKING

func _on_take_damage(_new_hp: float) -> void:
	if current_state == State.DEAD: return
	
	sprite.play("reaction")
	
	if player:
		var push_dir = sign(global_position.x - player.global_position.x)
		if push_dir == 0: push_dir = 1.0
		knockback_velocity = Vector2(push_dir * 450.0, 0)
	
	await get_tree().create_timer(0.15).timeout
	if current_state == State.STALKING or current_state == State.COOLDOWN:
		sprite.play("idle")

func find_player_target() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

func is_counterable() -> bool:
	return current_state == State.TELL

func get_countered() -> void:
	die()

func die() -> void:
	if current_state == State.DEAD: return
	current_state = State.DEAD
	velocity = Vector2.ZERO
	counter_indicator.visible = false
	
	$CollisionShape2D.set_deferred("disabled", true)
	var hitbox = get_node_or_null("HitboxComponent") as Area2D
	if hitbox:
		hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
		
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "rotation", 4.0, 0.25)
	tween.chain().tween_callback(queue_free)
