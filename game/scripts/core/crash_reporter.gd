extends Node

## Crash Reporter (F85)
## Captures unhandled errors and writes crash logs to user://crash_logs/.
## Includes timestamp, error message, stack trace, and game state snapshot.
## No personal data is collected. Future: auto-submit option.


## Constants
const CRASH_LOG_DIR := "user://crash_logs"
const MAX_CRASH_LOGS := 20  # Keep at most 20 crash logs

## State
var _is_initialized: bool = false
var _error_count: int = 0


func _ready() -> void:
	_ensure_crash_log_dir()
	_is_initialized = true
	print("[CrashReporter] Initialized, crash logs at: %s" % CRASH_LOG_DIR)


## Report an error with context. Call this from error-prone code paths.
func report_error(error_message: String, context: Dictionary = {}) -> String:
	_error_count += 1

	var report := _build_crash_report(error_message, context)
	var filepath := _write_crash_report(report)

	print("[CrashReporter] Error logged: %s -> %s" % [error_message, filepath])
	return filepath


## Report a critical/fatal error with full game state capture.
func report_crash(error_message: String) -> String:
	var context := _capture_game_state()
	var filepath := report_error(error_message, context)
	print("[CrashReporter] CRASH logged: %s" % error_message)
	return filepath


## Get a list of existing crash log file paths.
func get_crash_logs() -> Array:
	var logs: Array = []
	var dir = DirAccess.open(CRASH_LOG_DIR)
	if dir == null:
		return logs

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".log"):
			logs.append(CRASH_LOG_DIR + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	logs.sort()
	return logs


## Read a crash log's contents.
func read_crash_log(filepath: String) -> String:
	if not FileAccess.file_exists(filepath):
		return ""
	var file = FileAccess.open(filepath, FileAccess.READ)
	if file == null:
		return ""
	var content = file.get_as_text()
	file.close()
	return content


## Get the number of errors captured this session.
func get_error_count() -> int:
	return _error_count


## Delete all crash logs.
func clear_crash_logs() -> void:
	var logs = get_crash_logs()
	for log_path in logs:
		DirAccess.remove_absolute(log_path)
	print("[CrashReporter] Cleared %d crash logs" % logs.size())


## Build a crash report string.
func _build_crash_report(error_message: String, context: Dictionary) -> String:
	var report := ""

	# Header
	report += "=== CRASH REPORT ===\n"
	report += "Timestamp: %s\n" % Time.get_datetime_string_from_system(true)
	report += "Unix Time: %d\n" % Time.get_unix_time_from_system()
	report += "\n"

	# Application info
	report += "=== APPLICATION ===\n"
	report += "Game: Political Fighting Game\n"
	report += "Version: %s\n" % ProjectSettings.get_setting("application/config/version", "unknown")
	report += "Godot: %s\n" % Engine.get_version_info().get("string", "unknown")
	report += "Renderer: %s\n" % ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")
	report += "\n"

	# System info (no personal data)
	report += "=== SYSTEM ===\n"
	report += "OS: %s\n" % OS.get_name()
	report += "Processor Count: %d\n" % OS.get_processor_count()
	report += "Video Adapter: %s\n" % RenderingServer.get_video_adapter_name()
	report += "\n"

	# Error
	report += "=== ERROR ===\n"
	report += "Message: %s\n" % error_message
	report += "\n"

	# Stack trace
	report += "=== STACK TRACE ===\n"
	var stack = get_stack()
	if stack and stack.size() > 0:
		for frame in stack:
			report += "  %s:%d in %s()\n" % [
				frame.get("source", "unknown"),
				frame.get("line", 0),
				frame.get("function", "unknown"),
			]
	else:
		report += "  (stack trace unavailable)\n"
	report += "\n"

	# Game state context
	if not context.is_empty():
		report += "=== GAME STATE ===\n"
		for key in context:
			report += "  %s: %s\n" % [key, str(context[key])]
		report += "\n"

	report += "=== END REPORT ===\n"
	return report


## Capture current game state for crash context.
func _capture_game_state() -> Dictionary:
	var state := {}

	# GameManager state
	if is_instance_valid(GameManager):
		state["game_state"] = GameManager.get_current_state_name()
		state["battle_frame"] = GameManager.battle_frame
		state["current_round"] = GameManager.current_round
		state["round_timer_frames"] = GameManager.round_timer_frames
		state["is_paused"] = GameManager.is_paused
		state["rounds_won"] = str(GameManager.rounds_won)

	# Scene tree info
	var tree = get_tree()
	if tree:
		state["current_scene"] = tree.current_scene.name if tree.current_scene else "none"
		state["scene_tree_node_count"] = tree.get_node_count()

	# Performance
	state["fps"] = Engine.get_frames_per_second()
	state["physics_fps"] = Engine.physics_ticks_per_second
	state["memory_static_mb"] = "%.1f" % (OS.get_static_memory_usage() / 1048576.0)

	return state


## Write a crash report to a log file. Returns the file path.
func _write_crash_report(report: String) -> String:
	_ensure_crash_log_dir()

	# Generate filename from timestamp
	var datetime = Time.get_datetime_string_from_system(true).replace(":", "-").replace("T", "_")
	var filename = "crash_%s.log" % datetime
	var filepath = CRASH_LOG_DIR + "/" + filename

	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()

	# Prune old logs
	_prune_old_logs()

	return filepath


## Ensure the crash log directory exists.
func _ensure_crash_log_dir() -> void:
	if not DirAccess.dir_exists_absolute(CRASH_LOG_DIR):
		DirAccess.make_dir_recursive_absolute(CRASH_LOG_DIR)


## Remove old crash logs to stay under MAX_CRASH_LOGS.
func _prune_old_logs() -> void:
	var logs = get_crash_logs()
	while logs.size() > MAX_CRASH_LOGS:
		var oldest = logs.pop_front()
		DirAccess.remove_absolute(oldest)
