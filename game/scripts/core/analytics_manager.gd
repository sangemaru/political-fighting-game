extends Node

## Analytics Manager (F84)
## Lightweight, opt-in event tracking for gameplay telemetry.
## Events are stored locally in user://analytics/. Remote reporting is disabled
## by default and requires explicit opt-in.


## Constants
const ANALYTICS_DIR := "user://analytics"
const EVENTS_FILE := "user://analytics/events.json"
const MAX_EVENTS_PER_FILE := 500

## Configuration
var enabled: bool = false  # Opt-in only
var remote_reporting_enabled: bool = false  # Placeholder for future HTTP endpoint
var remote_endpoint: String = ""  # URL for remote reporting (disabled by default)

## In-memory event buffer
var _event_buffer: Array = []
var _session_id: String = ""
var _session_start_time: int = 0


func _ready() -> void:
	# Load opt-in preference from SettingsManager
	if SettingsManager:
		enabled = SettingsManager.get_setting("privacy", "analytics_enabled", false)

	if enabled:
		_start_session()


## Start a new analytics session.
func _start_session() -> void:
	_session_id = _generate_session_id()
	_session_start_time = Time.get_unix_time_from_system()
	_ensure_analytics_dir()
	track_event("session_started", {})
	print("[AnalyticsManager] Session started: %s" % _session_id)


## Track a gameplay event.
## event_name: Short identifier (e.g., "match_completed")
## data: Dictionary of event-specific data (must not contain personal info)
func track_event(event_name: String, data: Dictionary = {}) -> void:
	if not enabled:
		return

	var event := {
		"event": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": _session_id,
		"data": data,
	}

	_event_buffer.append(event)

	# Flush to disk periodically
	if _event_buffer.size() >= 50:
		flush_events()


## Convenience: track game started.
func track_game_started() -> void:
	track_event("game_started", {
		"version": ProjectSettings.get_setting("application/config/version", "unknown"),
	})


## Convenience: track match completed.
func track_match_completed(winner_id: int, p1_character: String, p2_character: String,
		rounds_played: int, stage: String) -> void:
	track_event("match_completed", {
		"winner_id": winner_id,
		"p1_character": p1_character,
		"p2_character": p2_character,
		"rounds_played": rounds_played,
		"stage": stage,
	})


## Convenience: track character selected.
func track_character_selected(player_id: int, character_id: String) -> void:
	track_event("character_selected", {
		"player_id": player_id,
		"character_id": character_id,
	})


## Convenience: track round won.
func track_round_won(winner_id: int, round_number: int, method: String) -> void:
	track_event("round_won", {
		"winner_id": winner_id,
		"round_number": round_number,
		"method": method,  # "ko", "timeout", "draw"
	})


## Flush buffered events to disk.
func flush_events() -> void:
	if _event_buffer.is_empty():
		return

	_ensure_analytics_dir()

	# Load existing events
	var existing_events := _load_events_from_disk()

	# Append new events
	existing_events.append_array(_event_buffer)

	# Trim if exceeding max
	if existing_events.size() > MAX_EVENTS_PER_FILE:
		existing_events = existing_events.slice(existing_events.size() - MAX_EVENTS_PER_FILE)

	# Write to disk
	var file = FileAccess.open(EVENTS_FILE, FileAccess.WRITE)
	if file:
		var json_str = JSON.stringify(existing_events, "\t")
		file.store_string(json_str)
		file.close()

	_event_buffer.clear()


## Enable or disable analytics. Integrates with SettingsManager.
func set_enabled(value: bool) -> void:
	enabled = value

	if SettingsManager:
		SettingsManager.set_setting("privacy", "analytics_enabled", value)

	if enabled and _session_id.is_empty():
		_start_session()
	elif not enabled:
		# Flush remaining events before disabling
		flush_events()
		print("[AnalyticsManager] Analytics disabled by user")


## Check if analytics is enabled.
func is_enabled() -> bool:
	return enabled


## Get event count stored on disk (for settings UI display).
func get_stored_event_count() -> int:
	var events := _load_events_from_disk()
	return events.size() + _event_buffer.size()


## Delete all stored analytics data.
func clear_all_data() -> void:
	_event_buffer.clear()
	if FileAccess.file_exists(EVENTS_FILE):
		DirAccess.remove_absolute(EVENTS_FILE)
	print("[AnalyticsManager] All analytics data cleared")


## Called when the application is about to quit.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if enabled:
			track_event("session_ended", {
				"duration_seconds": Time.get_unix_time_from_system() - _session_start_time,
			})
			flush_events()


## Load events from disk. Returns empty array if file doesn't exist.
func _load_events_from_disk() -> Array:
	if not FileAccess.file_exists(EVENTS_FILE):
		return []

	var file = FileAccess.open(EVENTS_FILE, FileAccess.READ)
	if file == null:
		return []

	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()

	if err != OK:
		return []

	var data = json.get_data()
	if data is Array:
		return data
	return []


## Ensure the analytics directory exists.
func _ensure_analytics_dir() -> void:
	if not DirAccess.dir_exists_absolute(ANALYTICS_DIR):
		DirAccess.make_dir_recursive_absolute(ANALYTICS_DIR)


## Generate a unique session ID without using randf().
## Uses timestamp + a hash of system info for uniqueness.
func _generate_session_id() -> String:
	var timestamp := Time.get_unix_time_from_system()
	var ticks := Time.get_ticks_msec()
	return "%d_%d" % [timestamp, ticks]
