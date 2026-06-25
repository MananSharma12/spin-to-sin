extends CharacterBody2D

@export var speed: float = 300.0
@export var base_damage: float = 10.0

@onready var attack_zone: Area2D = $AttackZone
@onready var attack_shape: CollisionShape2D = $AttackZone/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		sprite.flip_h = (direction < 0)
		
		if sprite.animation != "strike" and sprite.animation != "hurt":
			sprite.play("run")
		velocity.x = direction * speed
		sprite.flip_h = (direction < 0)
		
		if direction < 0:
			attack_zone.rotation = PI
		else:
			attack_zone.rotation = 0.0
		
		if sprite.animation != "strike" and sprite.animation != "hurt":
			sprite.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		if sprite.animation != "strike" and sprite.animation != "hurt":
			sprite.play("idle")

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		execute_attack()
	if event.is_action_pressed("counter"):
		execute_counter()

func execute_attack() -> void:
	if sprite.sprite_frames.has_animation("strike"):
		sprite.play("strike")
		if not sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)

	var final_damage = 9999.0 if Global.is_god_mode else base_damage
	var facing_direction = -1.0 if sprite.flip_h else 1.0
	
	var active_goons = get_tree().get_nodes_in_group("enemies")
	
	for goon in active_goons:
		if "current_state" in goon and goon.current_state != 4:
			var distance = global_position.distance_to(goon.global_position)
			var direction_to_goon = sign(goon.global_position.x - global_position.x)
			
			if distance <= 105.0 and (direction_to_goon == facing_direction or direction_to_goon == 0):
				print("[PUNCH CONNECTED]: Forcing hit registration on ", goon.name)
				
				var target_health_node = null
				for child in goon.get_children():
					if child.has_method("damage"):
						target_health_node = child
						break
				
				if target_health_node:
					target_health_node.damage(final_damage)
					
					if target_health_node.current_health <= 0 and goon.has_method("die"):
						print("  └─ [HEALTH EMPTY]: Direct force execution of enemy death sequence.")
						goon.die()
				else:
					if goon.has_method("die"):
						print("  └─ [EMERGENCY BYPASS]: No health component found. Forcing death state.")
						goon.die()

func execute_counter() -> void:
	if sprite.sprite_frames.has_animation("counter"):
		sprite.play("counter")
		if not sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)
			
	print("[PLAYER MATCH] Counter action key pressed.")
	
	var counter_was_successful: bool = false
	var facing_direction = -1.0 if sprite.flip_h else 1.0
	var active_goons = get_tree().get_nodes_in_group("enemies")
	
	for goon in active_goons:
		if "current_state" in goon and goon.current_state == 1: # 1 corresponds to State.TELL
			var distance = global_position.distance_to(goon.global_position)
			var direction_to_goon = sign(goon.global_position.x - global_position.x)
			
			if distance <= 85.0 and direction_to_goon == facing_direction:
				print("  └─ [COUNTER SUCCESS]: Intercepted goon via coordinate fallback!")
				goon.get_countered()
				counter_was_successful = true
				Global.combo_points += 1

	if counter_was_successful:
		Engine.time_scale = 0.05
		await get_tree().create_timer(0.015, true, false, true).timeout
		Engine.time_scale = 1.0

func _on_animation_finished() -> void:
	if sprite.animation == "strike" or sprite.animation == "counter":
		sprite.play("idle")

func _on_health_component_health_altered(new_value: Variant) -> void:
	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
		await get_tree().create_timer(0.15).timeout
		if sprite.animation == "hurt":
			sprite.play("idle")
