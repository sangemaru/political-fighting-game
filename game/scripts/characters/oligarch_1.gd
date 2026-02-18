extends BaseFighter

## The Oligarch Character Script
## A slow, tanky billionaire with high defense and devastating area attacks

class_name Oligarch1

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
	var file_path = "res://game/resources/characters/oligarch_1.json"
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

	self.max_health = base_stats.get("health", 110)
	self.health = self.max_health
	self.speed = base_stats.get("speed", 160)
	self.weight = base_stats.get("weight", 1.4)

	name = character_data.get("name", "The Oligarch")

	# Placeholder visual: gold for Oligarch
	if sprite:
		var img = Image.create(60, 80, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.9, 0.7, 0.1))
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
	var actual_damage = int(base_damage * character_data.get("base_stats", {}).get("attack_power", 1.1))

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
## Light Attack (Golden Handshake)
func get_light_attack_data() -> Dictionary:
	return {
		"name": "Golden Handshake",
		"damage": 7,
		"startup_frames": 4,
		"active_frames": 3,
		"recovery_frames": 6,
		"total_frames": 13,
		"knockback": 40
	}


## Heavy Attack (Market Crash)
func get_heavy_attack_data() -> Dictionary:
	return {
		"name": "Market Crash",
		"damage": 18,
		"startup_frames": 10,
		"active_frames": 4,
		"recovery_frames": 14,
		"total_frames": 28,
		"knockback": 200
	}


## Special Attack (Bailout)
func get_special_attack_data() -> Dictionary:
	return {
		"name": "Bailout",
		"damage": 10,
		"startup_frames": 6,
		"active_frames": 4,
		"recovery_frames": 18,
		"total_frames": 28,
		"knockback": 120,
		"effect": "counter"
	}


## Get character stats
func get_stats() -> Dictionary:
	var base_stats = character_data.get("base_stats", {})
	return {
		"health": base_stats.get("health", 110),
		"speed": base_stats.get("speed", 160),
		"weight": base_stats.get("weight", 1.4),
		"attack_power": base_stats.get("attack_power", 1.1),
		"defense": base_stats.get("defense", 1.3)
	}
