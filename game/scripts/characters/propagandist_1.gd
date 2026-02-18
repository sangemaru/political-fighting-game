extends BaseFighter

## The Propagandist Character Script
## A fast, fragile media manipulator with high attack power and deceptive moves

class_name Propagandist1

# Character data loaded from JSON
var character_data: Dictionary = {}


func _ready() -> void:
	super._ready()
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
	var file_path = "res://game/resources/characters/propagandist_1.json"
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

	var base_stats = character_data.get("base_stats", {})

	self.max_health = base_stats.get("health", 80)
	self.health = self.max_health
	self.speed = base_stats.get("speed", 240)
	self.weight = base_stats.get("weight", 0.7)

	name = character_data.get("name", "The Propagandist")

	# Placeholder visual: purple for Propagandist
	if sprite:
		var img = Image.create(60, 80, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.6, 0.1, 0.8))
		sprite.texture = ImageTexture.create_from_image(img)


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


## Return move data for the current attack (used by FighterStateMachine)
func get_move_data(is_special: bool) -> Dictionary:
	if is_special:
		return get_move("special")
	return get_move("light_attack")


## Execute a move
## Returns: Dictionary with move execution data
func execute_move(move_id: String) -> Dictionary:
	var move = get_move(move_id)

	if move.is_empty():
		push_error("Move not found: %s" % move_id)
		return {}

	# Calculate actual damage with modifiers
	var base_damage = move.get("damage", 0)
	var actual_damage = int(base_damage * character_data.get("base_stats", {}).get("attack_power", 1.3))

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
## Light Attack (Fake News)
func get_light_attack_data() -> Dictionary:
	return {
		"name": "Fake News",
		"damage": 5,
		"startup_frames": 2,
		"active_frames": 3,
		"recovery_frames": 4,
		"total_frames": 9,
		"knockback": 60
	}


## Heavy Attack (Spin Cycle)
func get_heavy_attack_data() -> Dictionary:
	return {
		"name": "Spin Cycle",
		"damage": 14,
		"startup_frames": 5,
		"active_frames": 5,
		"recovery_frames": 8,
		"total_frames": 18,
		"knockback": 160
	}


## Special Attack (Cancel Culture)
func get_special_attack_data() -> Dictionary:
	return {
		"name": "Cancel Culture",
		"damage": 8,
		"startup_frames": 7,
		"active_frames": 6,
		"recovery_frames": 10,
		"total_frames": 23,
		"knockback": 100,
		"effect": "debuff"
	}


## Get character stats
func get_stats() -> Dictionary:
	var base_stats = character_data.get("base_stats", {})
	return {
		"health": base_stats.get("health", 80),
		"speed": base_stats.get("speed", 240),
		"weight": base_stats.get("weight", 0.7),
		"attack_power": base_stats.get("attack_power", 1.3),
		"defense": base_stats.get("defense", 0.8)
	}
