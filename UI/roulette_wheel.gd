extends CanvasLayer

@onready var control_wrapper: Control = $Control
@onready var wheel_graphic: ColorRect = $Control/WheelTexturePlaceholder

var is_spinning: bool = false
var spin_velocity: float = 0.0
var decay_rate: float = 0.985 # Friction simulator

func _ready() -> void:
	control_wrapper.hide() # Keep hidden until the wave is cleared

func trigger_wheel_sequence() -> void:
	print("[WHEEL UI]: Wave clear signal intercepted! Displaying wheel matrix.")
	control_wrapper.show()
	is_spinning = true
	# Give it a massive random initial velocity to start spinning fast
	spin_velocity = randf_range(30.0, 50.0)

func _process(delta: float) -> void:
	if is_spinning:
		# Apply rotational force over time frame metrics
		wheel_graphic.rotation += spin_velocity * delta
		# Slowly drain velocity to simulate friction
		spin_velocity *= decay_rate
		
		# Once it grinds to a near halt, lock the result
		if spin_velocity <= 0.1:
			is_spinning = false
			spin_velocity = 0.0
			finalize_spin_outcome()

func finalize_spin_outcome() -> void:
	print("[WHEEL UI]: Spin concluded! Gun Mood parameter was: ", Global.current_gun_mood)
	
	# Increment global loop counters
	Global.current_wave += 1
	Global.combo_points = 0
	
	print("[SYSTEM LOOP]: Resetting sandbox parameters. Loading Wave ", Global.current_wave)
	
	# Force Godot to reload the current room instance to loop infinitely
	get_tree().reload_current_scene()
