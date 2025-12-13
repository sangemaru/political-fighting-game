extends Node

## Stage Loader
## Manages loading and instantiating stages from scenes and JSON data

class_name StageLoader

## Preload available stages
const STAGES = {
	"arena_1": "res://scenes/stages/arena_1.tscn"
}

const STAGE_DATA_PATH = "res://resources/stages/"


## Load a stage by ID
static func load_stage(stage_id: String) -> BaseStage:
	if not STAGES.has(stage_id):
		push_error("Stage not found: " + stage_id)
		return null

	var scene_path = STAGES[stage_id]
	if not ResourceLoader.exists(scene_path):
		push_error("Stage scene not found: " + scene_path)
		return null

	var stage_scene = load(scene_path)
	if stage_scene == null:
		push_error("Failed to load stage scene: " + scene_path)
		return null

	var stage_instance = stage_scene.instantiate()
	if not stage_instance is BaseStage:
		push_error("Loaded scene is not a BaseStage: " + scene_path)
		return null

	# Load stage data from JSON
	var data_path = STAGE_DATA_PATH + stage_id + ".json"
	if ResourceLoader.exists(data_path):
		stage_instance.load_from_resource(data_path)

	return stage_instance


## Get list of available stages
static func get_available_stages() -> PackedStringArray:
	return STAGES.keys()


## Check if a stage exists
static func stage_exists(stage_id: String) -> bool:
	return STAGES.has(stage_id)
