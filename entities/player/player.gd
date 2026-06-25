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


# ********************************************

func execute_attack() -> void:
	if sprite.sprite_frames.has_animation("strike"):
		sprite.play("strike")
		if not sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)

	var final_damage = 9999.0 if Global.is_god_mode else base_damage
	var overlapping_areas = attack_zone.get_overlapping_areas()
	var hit_landed: bool = false

	# 1. Standard Physics Attempt
	for area in overlapping_areas:
		var enemy = area.get_parent()
		if enemy and enemy.has_node("HealthComponent"):
			enemy.get_node("HealthComponent").damage(final_damage)
			hit_landed = true

	# 2. BRUTE FORCE JAM FALLBACK: If physics failed, check raw pixel distance
	if not hit_landed:
		var facing_direction = -1.0 if sprite.flip_h else 1.0
		var active_goons = get_tree().get_nodes_in_group("enemies")
		
		for goon in active_goons:
			if "current_state" in goon and goon.current_state != 4: # Ignore dead goons
				var distance = global_position.distance_to(goon.global_position)
				var direction_to_goon = sign(goon.global_position.x - global_position.x)
				
				# If within 75 pixels and you are facing their direction, force the kill
				if distance <= 75.0 and direction_to_goon == facing_direction:
					if goon.has_node("HealthComponent"):
						print("[JAM BYPASS]: Hit landed via coordinate math on left/right side!")
						goon.get_node("HealthComponent").damage(final_damage)

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
			
			# Coordinate check: close enough, facing them, and they are winding up
			if distance <= 85.0 and direction_to_goon == facing_direction:
				print("  └─ [COUNTER SUCCESS]: Intercepted goon via coordinate fallback!")
				goon.get_countered()
				counter_was_successful = true
				Global.combo_points += 1

	if counter_was_successful:
		Engine.time_scale = 0.05
		await get_tree().create_timer(0.015, true, false, true).timeout
		Engine.time_scale = 1.0

# ********************************************

#func execute_attack() -> void:
	#if sprite.sprite_frames.has_animation("strike"):
		#sprite.play("strike")
		#if not sprite.animation_finished.is_connected(_on_animation_finished):
			#sprite.animation_finished.connect(_on_animation_finished)
#
	#var overlapping_areas = attack_zone.get_overlapping_areas()
	#
	# === TEMPORARY DEBUG LOG: Remove or comment out once hit detection is verified ===
	#print("[COMBAT DEBUG] Hitbox polled. Overlapping areas found: ", overlapping_areas.size())
	#for area in overlapping_areas:
		#print("  └─ Overlapping Node Name: ", area.name, " | Root Parent: ", area.get_parent().name)
	# =================================================================================
#
	#for area in overlapping_areas:
		#if area.has_method("take_impact"):
			#var final_damage = 9999.0 if Global.is_god_mode else base_damage
			#area.take_impact(final_damage)

#func execute_counter() -> void:
	#print("[PLAYER MATCH] Counter action key pressed.")
	#
	#if sprite.sprite_frames.has_animation("counter"):
		#sprite.play("counter")
		#if not sprite.animation_finished.is_connected(_on_animation_finished):
			#sprite.animation_finished.connect(_on_animation_finished)
	#
	#var visual_rect = get_node_or_null("ColorRect") as ColorRect
	#if visual_rect:
		#var old_color = visual_rect.color
		#var tween = create_tween()
		#tween.tween_property(visual_rect, "color", Color.CYAN, 0.05)
		#tween.tween_property(visual_rect, "color", old_color, 0.08).set_delay(0.05)
#
	#var overlapping_areas = attack_zone.get_overlapping_areas()
	#
	## DIAGNOSTIC: Caught nothing at all
	#if overlapping_areas.size() == 0:
		#print("  └─ [COUNTER FAILED]: No targets inside AttackZone reach.")
		#return
#
	#var counter_was_successful: bool = false
	#
	#for area in overlapping_areas:
		#if area.has_method("take_impact"):
			#var enemy = area.get_parent()
			#if enemy:
				#if enemy.has_method("is_counterable"):
					#if enemy.is_counterable():
						#print("  └─ [COUNTER SUCCESS]: Intercepted ", enemy.name, " perfectly during its flash window!")
						#enemy.get_countered()
						#counter_was_successful = true
						#Global.combo_points += 1
						#print("     [COMBO UPDATE]: Multiplier increased to x", Global.combo_points)
					#else:
						## DIAGNOSTIC: Identify exactly why the timing missed
						#var enemy_state_string := "UNKNOWN"
						#if "current_state" in enemy:
							#match enemy.current_state:
								#0: enemy_state_string = "STALKING (You countered TOO EARLY, enemy hasn't wound up yet)"
								#2: enemy_state_string = "STRIKING (You countered TOO LATE, enemy blow already landed)"
								#3: enemy_state_string = "COOLDOWN (Enemy is resting between strikes)"
								#4: enemy_state_string = "DEAD"
						#print("  └─ [COUNTER FAILED]: Target ", enemy.name, " is not counterable. State is: ", enemy_state_string)
				#else:
					#print("  └─ [COUNTER CRITICAL]: Overlapping entity lacks 'is_counterable' implementation.")
#
	#if counter_was_successful:
		#Engine.time_scale = 0.05
		#await get_tree().create_timer(0.015, true, false, true).timeout
		#Engine.time_scale = 1.0

func _on_animation_finished() -> void:
	if sprite.animation == "strike" or sprite.animation == "counter":
		sprite.play("idle")


func _on_health_component_health_altered(new_value: Variant) -> void:
	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
		await get_tree().create_timer(0.15).timeout
		if sprite.animation == "hurt":
			sprite.play("idle")
