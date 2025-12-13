extends Node

## Character Data Loader
## Loads character stats from JSON files and validates against schema

class_name CharacterDataLoader

## Represents loaded character data
class CharacterData:
	var id: String
	var name: String
	var description: String
	var base_stats: Dictionary
	var moves: Array[MoveData]

	func _init(id: String, name: String, description: String, stats: Dictionary, moves: Array) -> void:
		self.id = id
		self.name = name
		self.description = description
		self.base_stats = stats
		self.moves = moves


## Represents a single move
class MoveData:
	var id: String
	var name: String
	var input: String
	var damage: int
	var startup_frames: int
	var active_frames: int
	var recovery_frames: int
	var knockback: float
	var hitbox: Dictionary  # offset_x, offset_y, width, height

	func _init(move_dict: Dictionary) -> void:
		id = move_dict.get("id", "")
		name = move_dict.get("name", "")
		input = move_dict.get("input", "")
		damage = move_dict.get("damage", 0)
		startup_frames = move_dict.get("startup_frames", 1)
		active_frames = move_dict.get("active_frames", 1)
		recovery_frames = move_dict.get("recovery_frames", 1)
		knockback = move_dict.get("knockback", 0.0)
		hitbox = move_dict.get("hitbox", {})


## Load character data from JSON file
func load_character(character_id: String) -> CharacterData:
	var file_path = _get_character_file_path(character_id)

	if not ResourceLoader.exists(file_path):
		push_error("Character file not found: %s" % file_path)
		return null

	var json_string = ResourceLoader.load(file_path).get_string()
	var parsed_data = JSON.parse_string(json_string)

	if parsed_data == null:
		push_error("Failed to parse JSON for character: %s" % character_id)
		return null

	# Validate against schema
	if not _validate_character_data(parsed_data):
		push_error("Character data validation failed: %s" % character_id)
		return null

	return _parse_character_data(parsed_data)


## Parse character data dictionary into CharacterData object
func _parse_character_data(data: Dictionary) -> CharacterData:
	var moves: Array[MoveData] = []

	if "moves" in data:
		for move_dict in data["moves"]:
			moves.append(MoveData.new(move_dict))

	return CharacterData.new(
		data.get("id", ""),
		data.get("name", ""),
		data.get("description", ""),
		data.get("base_stats", {}),
		moves
	)


## Validate character data against JSON schema
func _validate_character_data(data: Dictionary) -> bool:
	# Check required top-level fields
	var required_fields = ["id", "name", "description", "base_stats", "moves"]
	for field in required_fields:
		if field not in data:
			push_error("Missing required field: %s" % field)
			return false

	# Validate base_stats
	var base_stats = data.get("base_stats", {})
	var required_stats = ["health", "speed", "weight", "attack_power", "defense"]
	for stat in required_stats:
		if stat not in base_stats:
			push_error("Missing base_stat: %s" % stat)
			return false

	# Validate stat values
	if not _is_positive(base_stats.get("health")):
		push_error("health must be positive")
		return false
	if not _is_positive(base_stats.get("speed")):
		push_error("speed must be positive")
		return false
	if not _in_range(base_stats.get("weight"), 0.5, 2.0):
		push_error("weight must be between 0.5 and 2.0")
		return false
	if not _is_positive(base_stats.get("attack_power", 0.5)):
		push_error("attack_power must be positive")
		return false
	if not _is_positive(base_stats.get("defense", 0.5)):
		push_error("defense must be positive")
		return false

	# Validate moves array
	if not "moves" in data:
		push_error("moves array is required")
		return false

	var moves = data.get("moves", [])
	if not moves is Array:
		push_error("moves must be an array")
		return false

	for move in moves:
		if not _validate_move_data(move):
			return false

	return true


## Validate a single move
func _validate_move_data(move: Dictionary) -> bool:
	var required_fields = [
		"id", "name", "input", "damage",
		"startup_frames", "active_frames", "recovery_frames",
		"knockback", "hitbox"
	]

	for field in required_fields:
		if field not in move:
			push_error("Move missing required field: %s" % field)
			return false

	# Validate hitbox
	var hitbox = move.get("hitbox", {})
	var hitbox_fields = ["offset_x", "offset_y", "width", "height"]
	for field in hitbox_fields:
		if field not in hitbox:
			push_error("Hitbox missing required field: %s" % field)
			return false

	# Validate numeric ranges
	if move.get("damage", 0) < 0:
		push_error("Move damage cannot be negative")
		return false
	if move.get("startup_frames", 0) < 1:
		push_error("startup_frames must be >= 1")
		return false
	if move.get("active_frames", 0) < 1:
		push_error("active_frames must be >= 1")
		return false
	if move.get("recovery_frames", 0) < 1:
		push_error("recovery_frames must be >= 1")
		return false
	if move.get("knockback", 0) < 0:
		push_error("Move knockback cannot be negative")
		return false
	if hitbox.get("width", 0) < 1:
		push_error("Hitbox width must be >= 1")
		return false
	if hitbox.get("height", 0) < 1:
		push_error("Hitbox height must be >= 1")
		return false

	return true


## Helper: Check if value is positive
func _is_positive(value) -> bool:
	return value is int or value is float and value > 0


## Helper: Check if value is in range
func _in_range(value, min_val: float, max_val: float) -> bool:
	return value is int or value is float and value >= min_val and value <= max_val


## Get file path for character JSON
func _get_character_file_path(character_id: String) -> String:
	return "res://game/resources/characters/%s.json" % character_id
