extends Node

var player_health: float = 100.0
var combo_points: int = 0
var current_wave: int = 1
var is_god_mode: bool = false

# Modifier Variables altered by the Roulette Wheel
var player_damage_multiplier: float = 1.0
var enemy_speed_multiplier: float = 1.0

enum GunMood { HAPPY, ANGRY, NAUGHTY }
var current_gun_mood: GunMood = GunMood.HAPPY

# Evaluates the wave metrics to dictate dialogue and wheel layout weighting
func process_wave_performance(time_taken: float, hp_lost: float) -> void:
	print("\n[GLOBAL EVALUATION]: Processing wave metrics...")
	print("Time Taken: ", time_taken, "s | HP Lost: ", hp_lost)
	
	if hp_lost > 40.0 or time_taken > 30.0:
		current_gun_mood = GunMood.ANGRY
		enemy_speed_multiplier = 1.3 # Curse applied dynamically
		print(" -> GUN STATE: ANGRY. Curses weighted heavily.")
	elif combo_points >= 5:
		current_gun_mood = GunMood.NAUGHTY
		print(" -> GUN STATE: NAUGHTY. Chaos mechanics activated.")
	else:
		current_gun_mood = GunMood.HAPPY
		player_damage_multiplier = 1.5 # Buff applied dynamically
		print(" -> GUN STATE: HAPPY. Player buffed.")
