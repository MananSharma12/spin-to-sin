extends CharacterBody2D

@export var speed: float = 300.0
@export var base_damage: float = 10.0

@onready var attack_zone: Area2D = $AttackZone
@onready var attack_shape: CollisionShape2D = $AttackZone/CollisionShape2D

func _ready() -> void:
	adjust_attack_range()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Lateral Movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * speed
		attack_zone.scale.x = sign(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		execute_attack()

func adjust_attack_range() -> void:
	if Global.is_god_mode:
		attack_shape.shape.extents = Vector2(500, 16)
		attack_zone.position.x = 500
	else:
		attack_shape.shape.extents = Vector2(20, 32)
		attack_zone.position.x = 20
		
func execute_attack() -> void:
	print("Player attacked! God Mode status: ", Global.is_god_mode)
	var overlapping_areas = attack_zone.get_overlapping_areas()
	
	for area in overlapping_areas:
		if area is HitboxComponent:
			var final_damage = 9999.0 if Global.is_god_mode else base_damage
			print("Hit registered! Damage dealt: ", final_damage)
			area.take_impact(final_damage)
