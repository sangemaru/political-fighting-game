## Scene manager for handling scene transitions
## Provides preloading and transition with optional fade effects
##
## Usage:
##   SceneManager.goto_scene("res://scenes/menu.tscn")

extends Node

## Fade animation duration
var fade_duration: float = 0.5

## Preloaded scenes for quick access
var _preloaded_scenes: Dictionary = {}

## Current scene reference
var _current_scene: Node = null

## Fade canvas for transitions
var _fade_canvas: CanvasLayer = null
var _fade_rect: ColorRect = null

## Is transition in progress
var _is_transitioning: bool = false


func _ready() -> void:
	print("[SceneManager] _ready() called")
	_setup_fade_canvas()
	_current_scene = get_tree().root.get_child(get_tree().root.get_child_count() - 1)
	print("[SceneManager] Current scene: %s" % (_current_scene.name if _current_scene else "null"))


## Setup fade overlay canvas
func _setup_fade_canvas() -> void:
	_fade_canvas = CanvasLayer.new()
	_fade_canvas.layer = 1000  # Ensure it's on top
	add_child(_fade_canvas)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.anchor_left = 0.0
	_fade_rect.anchor_top = 0.0
	_fade_rect.anchor_right = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.modulate.a = 0.0  # Start transparent
	_fade_canvas.add_child(_fade_rect)


## Preload a scene for faster access
func preload_scene(scene_path: String) -> void:
	if not _preloaded_scenes.has(scene_path):
		_preloaded_scenes[scene_path] = load(scene_path)


## Preload multiple scenes
func preload_scenes(scene_paths: Array) -> void:
	for path in scene_paths:
		preload_scene(path)


## Goto a new scene with fade transition
## If use_fade is true, performs fade in/out animation
func goto_scene(scene_path: String, use_fade: bool = true) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true

	if use_fade:
		await _fade_out()

	# Load scene
	var scene_resource = _preloaded_scenes.get(scene_path)
	if scene_resource == null:
		scene_resource = load(scene_path)

	if scene_resource == null:
		push_error("Failed to load scene: " + scene_path)
		_is_transitioning = false
		return

	# Unload current scene
	if _current_scene != null:
		_current_scene.queue_free()

	# Create new scene instance
	_current_scene = scene_resource.instantiate()
	get_tree().root.add_child(_current_scene)

	if use_fade:
		await _fade_in()

	_is_transitioning = false


## Reload the current scene
func reload_current_scene(use_fade: bool = true) -> void:
	if _current_scene == null:
		return

	var scene_path = _current_scene.scene_file_path
	if scene_path == "":
		push_error("Current scene has no file path, cannot reload")
		return

	goto_scene(scene_path, use_fade)


## Fade out animation
func _fade_out() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_fade_rect, "modulate:a", 1.0, fade_duration)
	await tween.finished


## Fade in animation
func _fade_in() -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(_fade_rect, "modulate:a", 0.0, fade_duration)
	await tween.finished


## Check if transition is in progress
func is_transitioning() -> bool:
	return _is_transitioning


## Get current scene
func get_current_scene() -> Node:
	return _current_scene
