extends Node

const SETTINGS_PATH = "user://settings.cfg"
var config: ConfigFile

signal settings_changed(section: String, key: String, value)

func _ready():
	load_settings()

func load_settings() -> void:
	config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	if err != OK:
		print("Settings file not found, creating defaults...")
		_set_defaults()
	_apply_settings()

func _set_defaults() -> void:
	# Audio defaults
	config.set_value("audio", "sfx_volume", 0.8)
	config.set_value("audio", "music_volume", 0.6)

	# Video defaults
	config.set_value("video", "fullscreen", false)
	config.set_value("video", "vsync", true)

	# Game defaults
	config.set_value("game", "round_time", 99)
	config.set_value("game", "rounds_to_win", 2)

	save_settings()

func _apply_settings() -> void:
	# Apply audio settings
	if AudioManager:
		var sfx_vol = get_setting("audio", "sfx_volume", 0.8)
		var music_vol = get_setting("audio", "music_volume", 0.6)
		AudioManager.set_sfx_volume(sfx_vol)
		AudioManager.set_music_volume(music_vol)

	# Apply video settings
	var fullscreen = get_setting("video", "fullscreen", false)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	var vsync = get_setting("video", "vsync", true)
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

	# Apply custom input mappings if they exist
	_load_custom_input_mappings()

func _load_custom_input_mappings() -> void:
	# Check if custom input mappings are saved
	if not config.has_section("input"):
		return

	var actions = config.get_section_keys("input")
	for action in actions:
		var event_data_array = config.get_value("input", action, [])
		if event_data_array.is_empty():
			continue

		# Clear existing events for this action
		InputMap.action_erase_events(action)

		# Add custom events
		for event_data in event_data_array:
			var event = _deserialize_event(event_data)
			if event:
				InputMap.action_add_event(action, event)

func _deserialize_event(data: Dictionary) -> InputEvent:
	if data.get("type") == "key":
		var event = InputEventKey.new()
		event.keycode = data.get("keycode", 0)
		return event
	elif data.get("type") == "joypad_button":
		var event = InputEventJoypadButton.new()
		event.device = data.get("device", 0)
		event.button_index = data.get("button_index", 0)
		event.pressed = true
		return event
	elif data.get("type") == "joypad_motion":
		var event = InputEventJoypadMotion.new()
		event.device = data.get("device", 0)
		event.axis = data.get("axis", 0)
		event.axis_value = data.get("axis_value", 0.0)
		return event
	return null

func save_settings() -> void:
	var err = config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Failed to save settings: " + str(err))
	else:
		print("Settings saved successfully")

func get_setting(section: String, key: String, default):
	return config.get_value(section, key, default)

func set_setting(section: String, key: String, value) -> void:
	config.set_value(section, key, value)
	save_settings()
	_apply_settings()
	settings_changed.emit(section, key, value)

# Convenience methods for common settings
func set_sfx_volume(volume: float) -> void:
	set_setting("audio", "sfx_volume", clamp(volume, 0.0, 1.0))

func set_music_volume(volume: float) -> void:
	set_setting("audio", "music_volume", clamp(volume, 0.0, 1.0))

func set_fullscreen(enabled: bool) -> void:
	set_setting("video", "fullscreen", enabled)

func get_sfx_volume() -> float:
	return get_setting("audio", "sfx_volume", 0.8)

func get_music_volume() -> float:
	return get_setting("audio", "music_volume", 0.6)

func is_fullscreen() -> bool:
	return get_setting("video", "fullscreen", false)
