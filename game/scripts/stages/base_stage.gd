extends Node2D

## Base Stage Class
## Handles stage properties, boundaries, spawn points, and collisions
## All stages inherit from this base class

class_name BaseStage

## Signals
signal stage_loaded(stage_id: String)
signal player_out_of_bounds(player_id: int)

## Stage Properties
@export var stage_name: String = "Unnamed Stage"
@export var stage_id: String = ""

## Boundary Properties
var boundaries: Dictionary = {
	"left": 50,
	"right": 1230,
	"top": 0,
	"bottom": 650
}

## Spawn Points
var spawn_points: Dictionary = {
	"player_1": Vector2(320, 650),
	"player_2": Vector2(960, 650)
}

## Camera Limits
var camera_limits: Dictionary = {
	"left": 0,
	"right": 1280,
	"top": 0,
	"bottom": 720
}

## References
var ground_collision: StaticBody2D = null
var left_wall: StaticBody2D = null
var right_wall: StaticBody2D = null
var camera_2d: Camera2D = null

## State
var is_loaded: bool = false


func _ready() -> void:
	_setup_stage()
	stage_loaded.emit(stage_id)
	is_loaded = true


## Load stage data from JSON resource
func load_from_resource(resource_path: String) -> bool:
	if not ResourceLoader.exists(resource_path):
		push_error("Stage resource not found: " + resource_path)
		return false

	var file = FileAccess.open(resource_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open stage resource: " + resource_path)
		return false

	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("Failed to parse stage JSON: " + resource_path)
		return false

	var data = json.data
	if data == null:
		push_error("Invalid stage data: " + resource_path)
		return false

	# Load basic properties
	if data.has("id"):
		stage_id = data["id"]
	if data.has("name"):
		stage_name = data["name"]

	# Load boundaries
	if data.has("boundaries"):
		var bounds = data["boundaries"]
		boundaries = {
			"left": bounds.get("left", 50),
			"right": bounds.get("right", 1230),
			"top": bounds.get("top", 0),
			"bottom": bounds.get("bottom", 650)
		}

	# Load spawn points
	if data.has("spawn_points"):
		var spawns = data["spawn_points"]
		if spawns.has("player_1"):
			var p1 = spawns["player_1"]
			spawn_points["player_1"] = Vector2(p1.get("x", 320), p1.get("y", 650))
		if spawns.has("player_2"):
			var p2 = spawns["player_2"]
			spawn_points["player_2"] = Vector2(p2.get("x", 960), p2.get("y", 650))

	# Load camera configuration
	if data.has("camera"):
		var cam = data["camera"]
		camera_limits = {
			"left": cam.get("limit_left", 0),
			"right": cam.get("limit_right", 1280),
			"top": cam.get("limit_top", 0),
			"bottom": cam.get("limit_bottom", 720)
		}

	return true


## Setup stage visual elements and collisions
func _setup_stage() -> void:
	_setup_ground()
	_setup_walls()
	_setup_camera()


## Create ground collision
func _setup_ground() -> void:
	ground_collision = StaticBody2D.new()
	ground_collision.name = "Ground"
	ground_collision.position = Vector2.ZERO
	add_child(ground_collision)

	# Ground body
	var ground_shape = CollisionShape2D.new()
	var ground_rect = RectangleShape2D.new()
	ground_rect.size = Vector2(
		boundaries["right"] - boundaries["left"],
		20
	)
	ground_shape.shape = ground_rect
	ground_shape.position = Vector2(
		boundaries["left"] + (boundaries["right"] - boundaries["left"]) / 2,
		boundaries["bottom"] + 10
	)
	ground_collision.add_child(ground_shape)

	# Ground visual (if we want to see it)
	var ground_visual = ColorRect.new()
	ground_visual.size = Vector2(
		boundaries["right"] - boundaries["left"],
		20
	)
	ground_visual.position = Vector2(boundaries["left"], boundaries["bottom"])
	ground_visual.color = Color.DARK_GRAY
	add_child(ground_visual)


## Create invisible walls at stage boundaries
func _setup_walls() -> void:
	# Left wall
	left_wall = StaticBody2D.new()
	left_wall.name = "LeftWall"
	left_wall.position = Vector2(boundaries["left"], 0)
	add_child(left_wall)

	var left_shape = CollisionShape2D.new()
	var left_rect = RectangleShape2D.new()
	left_rect.size = Vector2(10, boundaries["bottom"])
	left_shape.shape = left_rect
	left_shape.position = Vector2(0, boundaries["bottom"] / 2)
	left_wall.add_child(left_shape)

	# Right wall
	right_wall = StaticBody2D.new()
	right_wall.name = "RightWall"
	right_wall.position = Vector2(boundaries["right"] - 10, 0)
	add_child(right_wall)

	var right_shape = CollisionShape2D.new()
	var right_rect = RectangleShape2D.new()
	right_rect.size = Vector2(10, boundaries["bottom"])
	right_shape.shape = right_rect
	right_shape.position = Vector2(0, boundaries["bottom"] / 2)
	right_wall.add_child(right_shape)


## Setup camera configuration
func _setup_camera() -> void:
	camera_2d = Camera2D.new()
	camera_2d.name = "StageCamera"
	add_child(camera_2d)

	# Set camera limits
	camera_2d.limit_left = int(camera_limits["left"])
	camera_2d.limit_right = int(camera_limits["right"])
	camera_2d.limit_top = int(camera_limits["top"])
	camera_2d.limit_bottom = int(camera_limits["bottom"])

	# Fixed camera for MVP (center on stage)
	camera_2d.global_position = Vector2(
		(boundaries["left"] + boundaries["right"]) / 2,
		(boundaries["top"] + boundaries["bottom"]) / 2
	)


## Get spawn position for a player
func get_spawn_position(player_id: int) -> Vector2:
	if player_id == 1:
		return spawn_points.get("player_1", Vector2(320, 650))
	elif player_id == 2:
		return spawn_points.get("player_2", Vector2(960, 650))
	else:
		push_error("Invalid player_id: " + str(player_id))
		return Vector2.ZERO


## Check if a position is within stage boundaries
func is_in_bounds(position: Vector2) -> bool:
	return (
		position.x >= boundaries["left"] and
		position.x <= boundaries["right"] and
		position.y >= boundaries["top"] and
		position.y <= boundaries["bottom"]
	)


## Get stage center point
func get_stage_center() -> Vector2:
	return Vector2(
		(boundaries["left"] + boundaries["right"]) / 2,
		(boundaries["top"] + boundaries["bottom"]) / 2
	)


## Get stage width
func get_stage_width() -> float:
	return boundaries["right"] - boundaries["left"]


## Get stage height
func get_stage_height() -> float:
	return boundaries["bottom"] - boundaries["top"]
