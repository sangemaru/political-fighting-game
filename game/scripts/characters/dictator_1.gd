extends BaseFighter

## The Generalissimo Character Script
## A slow, heavy-hitting military dictator with tank-like properties

class_name Dictator1

# Character data loaded from JSON
var character_data: Dictionary = {}


func _ready() -> void:
	# Load character data from JSON
	character_data = load_character_data()
	initialize_character()


func _process(delta: float) -> void:
	# Update animation and visual state
	pass


func _physics_process(delta: float) -> void:
	# Handle physics and collision
	pass


## Load character data from JSON file
func load_character_data() -> Dictionary:
	var file_path = "res://game/resources/characters/dictator_1.json"
	var file = FileAccess.open(file_path, FileAccess.READ)

	if file == null:
		push_error("Failed to load character data: %s" % file_path)
		return {}

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())

	if parse_result != OK:
		push_error("Failed to parse character JSON: %s" % file_path)
		return {}

	return json.get_data()


## Initialize character with loaded stats
func initialize_character() -> void:
	if character_data.is_empty():
		push_error("Character data not loaded")
		return

	# Set base stats
	var base_stats = character_data.get("base_stats", {})

	# These would be used by the battle system
	var health = base_stats.get("health", 100)
	var speed = base_stats.get("speed", 180)
	var weight = base_stats.get("weight", 1.2)
	var attack_power = base_stats.get("attack_power", 1.2)
	var defense = base_stats.get("defense", 1.0)

	# Initialize position and name
	name = character_data.get("name", "The Generalissimo")


## Get a specific move by ID
func get_move(move_id: String) -> Dictionary:
	var moves = character_data.get("moves", [])

	for move in moves:
		if move.get("id") == move_id:
			return move

	return {}


## Get all available moves
func get_all_moves() -> Array:
	return character_data.get("moves", [])


## Execute a move
## Returns: Dictionary with move execution data
func execute_move(move_id: String) -> Dictionary:
	var move = get_move(move_id)

	if move.is_empty():
		push_error("Move not found: %s" % move_id)
		return {}

	# Calculate actual damage with modifiers
	var base_damage = move.get("damage", 0)
	var actual_damage = int(base_damage * character_data.get("base_stats", {}).get("attack_power", 1.2))

	# Get hitbox data
	var hitbox = move.get("hitbox", {})
	var hitbox_data = {
		"offset": Vector2(hitbox.get("offset_x", 0), hitbox.get("offset_y", 0)),
		"size": Vector2(hitbox.get("width", 50), hitbox.get("height", 50))
	}

	return {
		"move_id": move_id,
		"name": move.get("name", ""),
		"damage": actual_damage,
		"startup_frames": move.get("startup_frames", 0),
		"active_frames": move.get("active_frames", 0),
		"recovery_frames": move.get("recovery_frames", 0),
		"knockback": move.get("knockback", 0),
		"hitbox": hitbox_data
	}


## Move frame data reference for combat system
## Light Attack (Command Jab)
func get_light_attack_data() -> Dictionary:
	return {
		"name": "Command Jab",
		"damage": 8,
		"startup_frames": 3,
		"active_frames": 2,
		"recovery_frames": 5,
		"total_frames": 10,
		"knockback": 50
	}


## Heavy Attack (Overhead Slam)
func get_heavy_attack_data() -> Dictionary:
	return {
		"name": "Overhead Slam",
		"damage": 15,
		"startup_frames": 8,
		"active_frames": 3,
		"recovery_frames": 12,
		"total_frames": 23,
		"knockback": 180
	}


## Special Attack (Propaganda Shout)
func get_special_attack_data() -> Dictionary:
	return {
		"name": "Propaganda Shout",
		"damage": 5,
		"startup_frames": 10,
		"active_frames": 5,
		"recovery_frames": 15,
		"total_frames": 30,
		"knockback": 200,
		"effect": "pushback"
	}


## Get character stats
func get_stats() -> Dictionary:
	var base_stats = character_data.get("base_stats", {})
	return {
		"health": base_stats.get("health", 100),
		"speed": base_stats.get("speed", 180),
		"weight": base_stats.get("weight", 1.2),
		"attack_power": base_stats.get("attack_power", 1.2),
		"defense": base_stats.get("defense", 1.0)
	}
