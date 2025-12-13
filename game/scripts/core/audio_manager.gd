extends Node
## AudioManager - Singleton for managing game audio (SFX and Music)
##
## Provides centralized audio playback with:
## - SFX pooling for concurrent sounds
## - Music crossfading
## - Volume control per bus
## - Sound/music registration by name

# === CONSTANTS ===
const SFX_POOL_SIZE = 8  # Number of concurrent SFX players
const CROSSFADE_DURATION = 1.0  # Seconds for music crossfade

# === AUDIO BUSES ===
var sfx_bus_index: int = 0
var music_bus_index: int = 0

# === SFX SYSTEM ===
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_player_index: int = 0
var sfx_library: Dictionary = {}  # sound_name -> AudioStream

# === MUSIC SYSTEM ===
var music_player_a: AudioStreamPlayer
var music_player_b: AudioStreamPlayer
var current_music_player: AudioStreamPlayer
var music_library: Dictionary = {}  # track_name -> AudioStream
var crossfade_tween: Tween

# === LIFECYCLE ===

func _ready() -> void:
	# Get bus indices
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	music_bus_index = AudioServer.get_bus_index("Music")

	# Create SFX pool
	for i in SFX_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

	# Create music players for crossfading
	music_player_a = AudioStreamPlayer.new()
	music_player_a.bus = "Music"
	add_child(music_player_a)

	music_player_b = AudioStreamPlayer.new()
	music_player_b.bus = "Music"
	add_child(music_player_b)

	current_music_player = music_player_a

	# Load audio files
	_load_audio_library()

	print("[AudioManager] Initialized with %d SFX players" % SFX_POOL_SIZE)

func _load_audio_library() -> void:
	"""Load all audio files from resources/audio/"""
	# SFX - Hit sounds
	_register_sfx("light_hit", "res://resources/audio/sfx/light_hit.wav")
	_register_sfx("heavy_hit", "res://resources/audio/sfx/heavy_hit.wav")
	_register_sfx("block", "res://resources/audio/sfx/block.wav")
	_register_sfx("whiff", "res://resources/audio/sfx/whiff.wav")

	# SFX - Menu sounds
	_register_sfx("menu_select", "res://resources/audio/sfx/menu_select.wav")
	_register_sfx("menu_confirm", "res://resources/audio/sfx/menu_confirm.wav")
	_register_sfx("menu_back", "res://resources/audio/sfx/menu_back.wav")
	_register_sfx("menu_hover", "res://resources/audio/sfx/menu_hover.wav")

	# Music tracks
	_register_music("menu_theme", "res://resources/audio/music/menu_theme.ogg")
	_register_music("battle_theme", "res://resources/audio/music/battle_theme.ogg")
	_register_music("victory_theme", "res://resources/audio/music/victory_theme.ogg")

func _register_sfx(sound_name: String, path: String) -> void:
	"""Register a sound effect. Fails silently if file doesn't exist."""
	if ResourceLoader.exists(path):
		sfx_library[sound_name] = load(path)
	else:
		# Silent fallback for placeholder audio
		pass

func _register_music(track_name: String, path: String) -> void:
	"""Register a music track. Fails silently if file doesn't exist."""
	if ResourceLoader.exists(path):
		music_library[track_name] = load(path)
	else:
		# Silent fallback for placeholder audio
		pass

# === SFX PLAYBACK ===

func play_sfx(sound_name: String, volume_db: float = 0.0) -> void:
	"""Play a sound effect from the library."""
	if not sfx_library.has(sound_name):
		# Silent fail for missing audio
		return

	var player = sfx_players[sfx_player_index]
	player.stream = sfx_library[sound_name]
	player.volume_db = volume_db
	player.play()

	# Advance to next player (round-robin)
	sfx_player_index = (sfx_player_index + 1) % SFX_POOL_SIZE

# === MUSIC PLAYBACK ===

func play_music(track_name: String, crossfade: bool = true, loop: bool = true) -> void:
	"""Play a music track with optional crossfade."""
	if not music_library.has(track_name):
		# Silent fail for missing music
		return

	var stream = music_library[track_name]

	# Check if already playing this track
	if current_music_player.stream == stream and current_music_player.playing:
		return

	# Select the inactive player for crossfade
	var new_player = music_player_b if current_music_player == music_player_a else music_player_a

	new_player.stream = stream

	# CRITICAL: Can't set loop property directly on AudioStream, must use script
	# For now, connect to "finished" signal to loop manually
	if loop and not new_player.finished.is_connected(_on_music_finished):
		new_player.finished.connect(_on_music_finished.bind(new_player))

	if crossfade:
		_crossfade_to(new_player)
	else:
		current_music_player.stop()
		new_player.play()
		current_music_player = new_player

func _crossfade_to(new_player: AudioStreamPlayer) -> void:
	"""Crossfade from current music player to new player."""
	var old_player = current_music_player

	# Kill existing tween if any
	if crossfade_tween:
		crossfade_tween.kill()

	# Start new player at zero volume
	new_player.volume_db = -80.0
	new_player.play()

	# Create crossfade tween
	crossfade_tween = create_tween()
	crossfade_tween.set_parallel(true)
	crossfade_tween.tween_property(old_player, "volume_db", -80.0, CROSSFADE_DURATION)
	crossfade_tween.tween_property(new_player, "volume_db", 0.0, CROSSFADE_DURATION)

	# Stop old player when done
	crossfade_tween.chain().tween_callback(old_player.stop)

	current_music_player = new_player

func _on_music_finished(player: AudioStreamPlayer) -> void:
	"""Loop music when it finishes."""
	if player == current_music_player:
		player.play()

func stop_music(fadeout: bool = true) -> void:
	"""Stop currently playing music."""
	if fadeout:
		if crossfade_tween:
			crossfade_tween.kill()
		crossfade_tween = create_tween()
		crossfade_tween.tween_property(current_music_player, "volume_db", -80.0, CROSSFADE_DURATION)
		crossfade_tween.tween_callback(current_music_player.stop)
	else:
		current_music_player.stop()

# === VOLUME CONTROL ===

func set_sfx_volume(volume_linear: float) -> void:
	"""Set SFX volume (0.0 to 1.0)."""
	var volume_db = linear_to_db(volume_linear) if volume_linear > 0.0 else -80.0
	AudioServer.set_bus_volume_db(sfx_bus_index, volume_db)

func set_music_volume(volume_linear: float) -> void:
	"""Set Music volume (0.0 to 1.0)."""
	var volume_db = linear_to_db(volume_linear) if volume_linear > 0.0 else -80.0
	AudioServer.set_bus_volume_db(music_bus_index, volume_db)

func get_sfx_volume() -> float:
	"""Get current SFX volume (0.0 to 1.0)."""
	var db = AudioServer.get_bus_volume_db(sfx_bus_index)
	return db_to_linear(db) if db > -80.0 else 0.0

func get_music_volume() -> float:
	"""Get current Music volume (0.0 to 1.0)."""
	var db = AudioServer.get_bus_volume_db(music_bus_index)
	return db_to_linear(db) if db > -80.0 else 0.0

# === HELPERS ===

func linear_to_db(linear: float) -> float:
	"""Convert linear volume to decibels."""
	return 20.0 * log(linear) / log(10.0)

func db_to_linear(db: float) -> float:
	"""Convert decibels to linear volume."""
	return pow(10.0, db / 20.0)
