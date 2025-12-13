extends Node

## Stage Data Loader
## Utility for loading and parsing stage JSON data

class_name StageDataLoader


## Load stage data from a JSON file
static func load_stage_data(file_path: String) -> Dictionary:
	if not ResourceLoader.exists(file_path):
		push_error("Stage data file not found: " + file_path)
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open stage data file: " + file_path)
		return {}

	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("Failed to parse stage JSON: " + file_path)
		return {}

	var data = json.data
	if data == null:
		push_error("Invalid stage data: " + file_path)
		return {}

	return data


## Parse boundaries from stage data
static func parse_boundaries(data: Dictionary) -> Dictionary:
	if not data.has("boundaries"):
		push_warning("Stage data missing 'boundaries'")
		return {
			"left": 50,
			"right": 1230,
			"top": 0,
			"bottom": 650
		}

	var bounds = data["boundaries"]
	return {
		"left": bounds.get("left", 50),
		"right": bounds.get("right", 1230),
		"top": bounds.get("top", 0),
		"bottom": bounds.get("bottom", 650)
	}


## Parse spawn points from stage data
static func parse_spawn_points(data: Dictionary) -> Dictionary:
	if not data.has("spawn_points"):
		push_warning("Stage data missing 'spawn_points'")
		return {
			"player_1": Vector2(320, 650),
			"player_2": Vector2(960, 650)
		}

	var spawns = data["spawn_points"]
	var result = {}

	if spawns.has("player_1"):
		var p1 = spawns["player_1"]
		result["player_1"] = Vector2(p1.get("x", 320), p1.get("y", 650))
	else:
		result["player_1"] = Vector2(320, 650)

	if spawns.has("player_2"):
		var p2 = spawns["player_2"]
		result["player_2"] = Vector2(p2.get("x", 960), p2.get("y", 650))
	else:
		result["player_2"] = Vector2(960, 650)

	return result


## Parse camera configuration from stage data
static func parse_camera_config(data: Dictionary) -> Dictionary:
	if not data.has("camera"):
		push_warning("Stage data missing 'camera'")
		return {
			"enabled": false,
			"limit_left": 0,
			"limit_right": 1280,
			"limit_top": 0,
			"limit_bottom": 720
		}

	var cam = data["camera"]
	return {
		"enabled": cam.get("enabled", false),
		"limit_left": cam.get("limit_left", 0),
		"limit_right": cam.get("limit_right", 1280),
		"limit_top": cam.get("limit_top", 0),
		"limit_bottom": cam.get("limit_bottom", 720)
	}


## Parse hazards from stage data
static func parse_hazards(data: Dictionary) -> Array:
	if not data.has("hazards"):
		return []

	var hazards_array = data["hazards"]
	if not hazards_array is Array:
		push_warning("'hazards' is not an array")
		return []

	return hazards_array


## Get stage metadata
static func get_stage_metadata(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", "unknown"),
		"name": data.get("name", "Unnamed Stage"),
		"description": data.get("description", "No description available")
	}
