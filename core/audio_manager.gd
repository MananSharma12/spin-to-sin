extends Node

var music_player: AudioStreamPlayer
var current_tier: int = 0

@onready var tier_1_track = preload("res://music/combat/1.ogg")
@onready var tier_2_track = preload("res://music/combat/2.ogg")
@onready var tier_3_track = preload("res://music/combat/3.ogg")

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.volume_db = -14.0 # Comfort level background volume
	music_player.bus = "Master"

func update_combat_intensity(enemy_count: int) -> void:
	var target_tier: int = 1
	var target_stream: AudioStream = tier_1_track

	if enemy_count <= 4:
		target_tier = 1
		target_stream = tier_1_track
	elif enemy_count <= 10:
		target_tier = 2
		target_stream = tier_2_track
	else:
		target_tier = 3
		target_stream = tier_3_track

	if target_tier != current_tier:
		current_tier = target_tier
		music_player.stream = target_stream
		music_player.play()
		print("[DYNAMIC AUDIO]: Threat level shifted. Playing Tier ", current_tier, " (Enemies remaining: ", enemy_count, ")")
