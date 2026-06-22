extends CanvasLayer

@onready var health_bar: ProgressBar = $ProgressBar
@onready var tutorial_overlay: Control = $TutorialOverlay

var tutorial_active: bool = true

func _ready() -> void:
	call_deferred("initialize_health_binding")

func initialize_health_binding() -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player:
		var health_node = player.get_node_or_null("HealthComponent") as HealthComponent
		if health_node:
			health_bar.max_value = health_node.max_health
			health_bar.value = health_node.current_health
			health_node.health_altered.connect(_on_player_health_altered)
			print("[HUD]: Dynamic telemetry mapping online.")

func _input(event: InputEvent) -> void:
	if not tutorial_active:
		return
		
	if (event.is_action_pressed("move_left") or 
		event.is_action_pressed("move_right") or 
		event.is_action_pressed("attack") or 
		event.is_action_pressed("counter")):
			
			dismiss_tutorial_cards()

func dismiss_tutorial_cards() -> void:
	tutorial_active = false
	print("[HUD]: First input detected. Dissolving tutorial overlay matrix.")
	
	var tween = create_tween()
	tween.tween_property(tutorial_overlay, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(tutorial_overlay.queue_free)

func _on_player_health_altered(new_value: float) -> void:
	health_bar.value = new_value
