## Stage select screen script
## Allows players to select a stage/arena

extends Control

var available_stages: Array = []
var selected_stage: int = 0
var players_ready: bool = false

@onready var stage_name_label: Label = $VBoxContainer/StageNameLabel
@onready var stage_preview: ColorRect = $VBoxContainer/StagePreview
@onready var ready_label: Label = $VBoxContainer/ReadyLabel


func _ready() -> void:
	# Load available stages
	_load_stages()

	# Update initial display
	_update_display()


func _process(_delta: float) -> void:
	if not players_ready:
		# Any player can change stage selection
		if Input.is_action_just_pressed("p1_move_left") or Input.is_action_just_pressed("p2_move_left"):
			AudioManager.play_sfx("menu_select")
			selected_stage = (selected_stage - 1 + available_stages.size()) % available_stages.size()
			_update_display()
		elif Input.is_action_just_pressed("p1_move_right") or Input.is_action_just_pressed("p2_move_right"):
			AudioManager.play_sfx("menu_select")
			selected_stage = (selected_stage + 1) % available_stages.size()
			_update_display()

		# Any player can confirm
		if Input.is_action_just_pressed("p1_attack") or Input.is_action_just_pressed("p2_attack"):
			AudioManager.play_sfx("menu_confirm")
			players_ready = true
			_update_display()
			_on_stage_confirmed()

	# Back button
	if Input.is_action_just_pressed("ui_cancel"):
		AudioManager.play_sfx("menu_back")
		_on_back_pressed()


func _load_stages() -> void:
	# Load all stages (base game + mods) via ModLoader
	available_stages = []

	if ModLoader:
		var all_stages := ModLoader.get_all_stages()
		for stage_data in all_stages:
			var stage_id: String = stage_data.get("id", "")
			available_stages.append({
				"id": stage_id,
				"name": stage_data.get("name", "Unknown Stage"),
				"scene_path": "res://game/scenes/stages/%s.tscn" % stage_id,
				"_is_mod": stage_data.get("_is_mod", false)
			})
	else:
		# Fallback: load directly from stages resource directory
		var stage_dir = "res://game/resources/stages/"
		var dir = DirAccess.open(stage_dir)

		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()

			while file_name != "":
				if file_name.ends_with(".json"):
					var file_path = stage_dir + file_name
					var file = FileAccess.open(file_path, FileAccess.READ)
					if file:
						var json_text = file.get_as_text()
						var json = JSON.new()
						var parse_result = json.parse(json_text)

						if parse_result == OK:
							var stage_data = json.get_data()
							var stage_id = stage_data.get("id", "")
							available_stages.append({
								"id": stage_id,
								"name": stage_data.get("name", "Unknown Stage"),
								"scene_path": "res://game/scenes/stages/%s.tscn" % stage_id
							})

						file.close()

				file_name = dir.get_next()

			dir.list_dir_end()

	# Ensure we have at least one stage
	if available_stages.is_empty():
		push_error("No stages found!")
		available_stages = [
			{
				"id": "arena_1",
				"name": "Political Arena",
				"scene_path": "res://game/scenes/stages/arena_1.tscn"
			}
		]


func _update_display() -> void:
	if available_stages.is_empty():
		stage_name_label.text = "No stages available"
		return

	var stage = available_stages[selected_stage]
	stage_name_label.text = stage.get("name", "Unknown Stage")

	# Update preview (placeholder color for now)
	stage_preview.color = Color(0.2, 0.3, 0.4, 1.0)

	if players_ready:
		ready_label.text = "Loading..."
		ready_label.modulate = Color.GREEN
	else:
		ready_label.text = "Press SPACE or ENTER to continue"
		ready_label.modulate = Color.WHITE


func _on_stage_confirmed() -> void:
	# Proceed to battle scene
	if not available_stages.is_empty():
		var stage = available_stages[selected_stage]
		# For now, go directly to battle scene
		# TODO: Store stage selection in GameManager
		GameManager.selected_stage = stage.get("id", "arena_1")
		SceneManager.goto_scene("res://game/scenes/battle/battle.tscn")


func _on_back_pressed() -> void:
	# Return to character select
	SceneManager.goto_scene("res://game/scenes/menus/character_select.tscn")
