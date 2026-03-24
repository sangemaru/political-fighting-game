## Mod Loader
## Scans mods directory, validates manifests, and registers mod content
## Autoload as "ModLoader" in Project Settings > Autoload

extends Node

## Emitted when all mods have been scanned and loaded
signal mods_loaded
## Emitted when a mod fails validation
signal mod_load_failed(mod_id: String, reason: String)

## Base path for user mods
const MODS_DIR := "res://game/mods/"
## Current game version for compatibility checks
const GAME_VERSION := "0.1.0"
## Manifest filename expected in each mod subdirectory
const MANIFEST_FILE := "mod_manifest.json"

## Required fields in a mod manifest
const REQUIRED_MANIFEST_FIELDS := [
	"mod_id", "name", "version", "author", "description",
	"type", "game_version", "files"
]

## Valid mod types
const VALID_MOD_TYPES := ["character", "stage", "gameplay"]

## Loaded mod data, keyed by mod_id
var loaded_mods: Dictionary = {}
## Character data loaded from mods, keyed by character id
var modded_characters: Dictionary = {}
## Stage data loaded from mods, keyed by stage id
var modded_stages: Dictionary = {}
## Validation errors from the last scan, keyed by mod directory name
var validation_errors: Dictionary = {}


func _ready() -> void:
	scan_mods()


## Scan the mods directory and load all valid mods
func scan_mods() -> void:
	loaded_mods.clear()
	modded_characters.clear()
	modded_stages.clear()
	validation_errors.clear()

	var dir := DirAccess.open(MODS_DIR)
	if dir == null:
		print("[ModLoader] Mods directory not found or empty: %s" % MODS_DIR)
		mods_loaded.emit()
		return

	dir.list_dir_begin()
	var entry := dir.get_next()

	while entry != "":
		# Skip hidden directories and files
		if not entry.begins_with(".") and dir.current_is_dir():
			_try_load_mod(entry)
		entry = dir.get_next()

	dir.list_dir_end()

	var char_count := modded_characters.size()
	var stage_count := modded_stages.size()
	print("[ModLoader] Scan complete: %d mod(s) loaded (%d character(s), %d stage(s))" % [
		loaded_mods.size(), char_count, stage_count
	])

	mods_loaded.emit()


## Attempt to load a single mod from its directory
func _try_load_mod(dir_name: String) -> void:
	var mod_path := MODS_DIR + dir_name + "/"
	var manifest_path := mod_path + MANIFEST_FILE

	# Check manifest exists
	if not FileAccess.file_exists(manifest_path):
		_record_error(dir_name, "Missing %s" % MANIFEST_FILE)
		return

	# Parse manifest JSON
	var manifest := _load_json(manifest_path)
	if manifest.is_empty():
		_record_error(dir_name, "Failed to parse %s" % MANIFEST_FILE)
		return

	# Validate manifest
	var errors := _validate_manifest(manifest, mod_path)
	if not errors.is_empty():
		for error in errors:
			_record_error(dir_name, error)
		return

	var mod_id: String = manifest["mod_id"]

	# Check for duplicate mod_id
	if loaded_mods.has(mod_id):
		_record_error(dir_name, "Duplicate mod_id '%s' (already loaded)" % mod_id)
		return

	# Load mod content based on type
	var mod_type: String = manifest["type"]
	var success := false

	match mod_type:
		"character":
			success = _load_character_mod(manifest, mod_path)
		"stage":
			success = _load_stage_mod(manifest, mod_path)
		"gameplay":
			_record_error(dir_name, "Gameplay mods are not yet supported")
			return

	if success:
		loaded_mods[mod_id] = manifest
		print("[ModLoader] Loaded mod: %s (%s)" % [manifest["name"], mod_type])


## Load a character mod's data
func _load_character_mod(manifest: Dictionary, mod_path: String) -> bool:
	var files: Dictionary = manifest["files"]
	var data_path: String = mod_path + files["data"]

	if not FileAccess.file_exists(data_path):
		_record_error(manifest["mod_id"], "Character data file not found: %s" % files["data"])
		return false

	var char_data := _load_json(data_path)
	if char_data.is_empty():
		_record_error(manifest["mod_id"], "Failed to parse character data file")
		return false

	# Validate character data has minimum required fields
	var char_errors := _validate_character_data(char_data)
	if not char_errors.is_empty():
		for error in char_errors:
			_record_error(manifest["mod_id"], "Character data: %s" % error)
		return false

	var char_id: String = char_data["id"]

	# Mark as modded content
	char_data["_is_mod"] = true
	char_data["_mod_id"] = manifest["mod_id"]
	char_data["_mod_path"] = mod_path

	modded_characters[char_id] = char_data
	return true


## Load a stage mod's data
func _load_stage_mod(manifest: Dictionary, mod_path: String) -> bool:
	var files: Dictionary = manifest["files"]
	var data_path: String = mod_path + files["data"]

	if not FileAccess.file_exists(data_path):
		_record_error(manifest["mod_id"], "Stage data file not found: %s" % files["data"])
		return false

	var stage_data := _load_json(data_path)
	if stage_data.is_empty():
		_record_error(manifest["mod_id"], "Failed to parse stage data file")
		return false

	# Validate stage data has minimum required fields
	var stage_errors := _validate_stage_data(stage_data)
	if not stage_errors.is_empty():
		for error in stage_errors:
			_record_error(manifest["mod_id"], "Stage data: %s" % error)
		return false

	var stage_id: String = stage_data["id"]

	# Mark as modded content
	stage_data["_is_mod"] = true
	stage_data["_mod_id"] = manifest["mod_id"]
	stage_data["_mod_path"] = mod_path

	modded_stages[stage_id] = stage_data
	return true


## Validate a mod manifest dictionary. Returns array of error strings (empty = valid).
func _validate_manifest(manifest: Dictionary, mod_path: String) -> Array:
	var errors: Array = []

	# Check required fields
	for field in REQUIRED_MANIFEST_FIELDS:
		if field not in manifest:
			errors.append("Missing required field: %s" % field)

	if not errors.is_empty():
		return errors

	# Validate mod_id format (lowercase alphanumeric + underscores)
	var mod_id: String = manifest["mod_id"]
	var id_regex := RegEx.new()
	id_regex.compile("^[a-z0-9_]+$")
	if id_regex.search(mod_id) == null:
		errors.append("mod_id must be lowercase alphanumeric with underscores only: '%s'" % mod_id)

	# Validate type
	var mod_type: String = manifest.get("type", "")
	if mod_type not in VALID_MOD_TYPES:
		errors.append("Invalid mod type '%s'. Must be one of: %s" % [mod_type, ", ".join(VALID_MOD_TYPES)])

	# Validate version format
	var version: String = manifest.get("version", "")
	var ver_regex := RegEx.new()
	ver_regex.compile("^\\d+\\.\\d+\\.\\d+$")
	if ver_regex.search(version) == null:
		errors.append("Invalid version format '%s'. Expected semver (e.g., 1.0.0)" % version)

	# Validate game_version compatibility
	var game_ver: String = manifest.get("game_version", "")
	if not _is_version_compatible(game_ver):
		errors.append("Mod requires game version %s, but current is %s" % [game_ver, GAME_VERSION])

	# Validate files section
	var files = manifest.get("files", {})
	if not files is Dictionary:
		errors.append("'files' must be an object")
	elif not files.has("data"):
		errors.append("'files' must include a 'data' field")
	else:
		# Check that the referenced data file exists
		var data_file: String = mod_path + files["data"]
		if not FileAccess.file_exists(data_file):
			errors.append("Referenced data file not found: %s" % files["data"])

	return errors


## Validate character data has the minimum required structure
func _validate_character_data(data: Dictionary) -> Array:
	var errors: Array = []
	var required := ["id", "name", "description", "base_stats", "moves"]

	for field in required:
		if field not in data:
			errors.append("Missing required field: %s" % field)

	if errors.size() > 0:
		return errors

	# Validate base_stats
	var stats: Dictionary = data.get("base_stats", {})
	var required_stats := ["health", "speed", "weight", "attack_power", "defense"]
	for stat in required_stats:
		if stat not in stats:
			errors.append("Missing base_stat: %s" % stat)

	# Validate moves is an array with at least one move
	var moves = data.get("moves", [])
	if not moves is Array:
		errors.append("'moves' must be an array")
	elif moves.size() == 0:
		errors.append("Character must have at least one move")
	else:
		for i in range(moves.size()):
			var move = moves[i]
			if not move is Dictionary:
				errors.append("Move %d is not a valid object" % i)
				continue
			var move_fields := ["id", "name", "input", "damage", "startup_frames",
				"active_frames", "recovery_frames", "knockback", "hitbox"]
			for field in move_fields:
				if field not in move:
					errors.append("Move %d missing field: %s" % [i, field])

	return errors


## Validate stage data has the minimum required structure
func _validate_stage_data(data: Dictionary) -> Array:
	var errors: Array = []
	var required := ["id", "name", "description", "boundaries", "spawn_points", "camera"]

	for field in required:
		if field not in data:
			errors.append("Missing required field: %s" % field)

	if errors.size() > 0:
		return errors

	# Validate boundaries
	var bounds: Dictionary = data.get("boundaries", {})
	for field in ["left", "right", "top", "bottom"]:
		if field not in bounds:
			errors.append("Missing boundary: %s" % field)

	# Validate spawn_points
	var spawns: Dictionary = data.get("spawn_points", {})
	for player in ["player_1", "player_2"]:
		if player not in spawns:
			errors.append("Missing spawn point: %s" % player)
		elif not spawns[player] is Dictionary:
			errors.append("Spawn point %s must be an object" % player)
		else:
			if "x" not in spawns[player] or "y" not in spawns[player]:
				errors.append("Spawn point %s must have x and y" % player)

	return errors


## Check if a required game version is compatible with the current version
func _is_version_compatible(required_version: String) -> bool:
	var required := required_version.split(".")
	var current := GAME_VERSION.split(".")

	if required.size() < 3 or current.size() < 3:
		return false

	# Simple comparison: required version must be <= current version
	for i in range(3):
		var req := required[i].to_int()
		var cur := current[i].to_int()
		if req < cur:
			return true
		elif req > cur:
			return false

	# Equal versions
	return true


## Load and parse a JSON file. Returns empty dictionary on failure.
func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("[ModLoader] Could not open file: %s" % path)
		return {}

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_warning("[ModLoader] JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}

	var result = json.get_data()
	if result == null or not result is Dictionary:
		push_warning("[ModLoader] JSON root is not an object in %s" % path)
		return {}

	return result


## Record a validation error for a mod
func _record_error(mod_dir: String, error: String) -> void:
	if not validation_errors.has(mod_dir):
		validation_errors[mod_dir] = []
	validation_errors[mod_dir].append(error)
	push_warning("[ModLoader] %s: %s" % [mod_dir, error])
	mod_load_failed.emit(mod_dir, error)


## Get all available characters (base game + mods) as an array of dictionaries
func get_all_characters() -> Array:
	var characters: Array = []

	# Load base game characters
	var char_dir := "res://game/resources/characters/"
	var dir := DirAccess.open(char_dir)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var data := _load_json(char_dir + file_name)
				if not data.is_empty():
					data["_is_mod"] = false
					characters.append(data)
			file_name = dir.get_next()
		dir.list_dir_end()

	# Append modded characters
	for char_id in modded_characters:
		characters.append(modded_characters[char_id])

	return characters


## Get all available stages (base game + mods) as an array of dictionaries
func get_all_stages() -> Array:
	var stages: Array = []

	# Load base game stages
	var stage_dir := "res://game/resources/stages/"
	var dir := DirAccess.open(stage_dir)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var data := _load_json(stage_dir + file_name)
				if not data.is_empty():
					data["_is_mod"] = false
					stages.append(data)
			file_name = dir.get_next()
		dir.list_dir_end()

	# Append modded stages
	for stage_id in modded_stages:
		stages.append(modded_stages[stage_id])

	return stages


## Get information about loaded mods
func get_loaded_mods_info() -> Array:
	var info: Array = []
	for mod_id in loaded_mods:
		var manifest: Dictionary = loaded_mods[mod_id]
		info.append({
			"mod_id": manifest["mod_id"],
			"name": manifest["name"],
			"version": manifest["version"],
			"author": manifest["author"],
			"type": manifest["type"],
			"description": manifest["description"]
		})
	return info


## Check if a specific mod is loaded
func is_mod_loaded(mod_id: String) -> bool:
	return loaded_mods.has(mod_id)
