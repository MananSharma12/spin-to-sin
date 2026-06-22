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
		attack_zone.scale.x = sign(direction)
		
		sprite.flip_h = (direction < 0)
		
		if sprite.sprite_frames.has_animation("run") and sprite.animation != "strike":
			sprite.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		if sprite.animation != "strike":
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

	var overlapping_areas = attack_zone.get_overlapping_areas()
	for area in overlapping_areas:
		if area is HitboxComponent:
			var final_damage = 9999.0 if Global.is_god_mode else base_damage
			area.take_impact(final_damage)

func execute_counter() -> void:
	print("[PLAYER MATCH] Counter action key pressed.")
	
	if sprite.sprite_frames.has_animation("counter"):
		sprite.play("counter")
		if not sprite.animation_finished.is_connected(_on_animation_finished):
			sprite.animation_finished.connect(_on_animation_finished)
	
	var visual_rect = get_node_or_null("ColorRect") as ColorRect
	if visual_rect:
		var old_color = visual_rect.color
		var tween = create_tween()
		tween.tween_property(visual_rect, "color", Color.CYAN, 0.05)
		tween.tween_property(visual_rect, "color", old_color, 0.08).set_delay(0.05)

	var overlapping_areas = attack_zone.get_overlapping_areas()
	
	# DIAGNOSTIC: Caught nothing at all
	if overlapping_areas.size() == 0:
		print("  └─ [COUNTER FAILED]: No targets inside AttackZone reach.")
		return

	var counter_was_successful: bool = false
	
	for area in overlapping_areas:
		if area is HitboxComponent:
			var enemy = area.get_parent()
			if enemy:
				if enemy.has_method("is_counterable"):
					if enemy.is_counterable():
						print("  └─ [COUNTER SUCCESS]: Intercepted ", enemy.name, " perfectly during its flash window!")
						enemy.get_countered()
						counter_was_successful = true
						Global.combo_points += 1
						print("     [COMBO UPDATE]: Multiplier increased to x", Global.combo_points)
					else:
						# DIAGNOSTIC: Identify exactly why the timing missed
						var enemy_state_string := "UNKNOWN"
						if "current_state" in enemy:
							match enemy.current_state:
								0: enemy_state_string = "STALKING (You countered TOO EARLY, enemy hasn't wound up yet)"
								2: enemy_state_string = "STRIKING (You countered TOO LATE, enemy blow already landed)"
								3: enemy_state_string = "COOLDOWN (Enemy is resting between strikes)"
								4: enemy_state_string = "DEAD"
						print("  └─ [COUNTER FAILED]: Target ", enemy.name, " is not counterable. State is: ", enemy_state_string)
				else:
					print("  └─ [COUNTER CRITICAL]: Overlapping entity lacks 'is_counterable' implementation.")

	if counter_was_successful:
		Engine.time_scale = 0.05
		await get_tree().create_timer(0.015, true, false, true).timeout
		Engine.time_scale = 1.0

func _on_animation_finished() -> void:
	if sprite.animation == "strike" or sprite.animation == "counter":
		sprite.play("idle")
