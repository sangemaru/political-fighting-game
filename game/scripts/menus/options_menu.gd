## Options menu script
## Placeholder for game settings

extends Control

@onready var master_volume_slider: HSlider = $VBoxContainer/MasterVolumeContainer/VolumeSlider
@onready var master_volume_label: Label = $VBoxContainer/MasterVolumeContainer/ValueLabel
@onready var music_volume_slider: HSlider = $VBoxContainer/MusicVolumeContainer/VolumeSlider
@onready var music_volume_label: Label = $VBoxContainer/MusicVolumeContainer/ValueLabel
@onready var sfx_volume_slider: HSlider = $VBoxContainer/SFXVolumeContainer/VolumeSlider
@onready var sfx_volume_label: Label = $VBoxContainer/SFXVolumeContainer/ValueLabel
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	# Connect slider signals
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	back_button.pressed.connect(_on_back_pressed)

	# Initialize values
	_update_volume_labels()

	# Focus back button
	back_button.grab_focus()


func _on_master_volume_changed(value: float) -> void:
	master_volume_label.text = str(int(value)) + "%"
	# TODO: Apply to audio system when implemented


func _on_music_volume_changed(value: float) -> void:
	music_volume_label.text = str(int(value)) + "%"
	# TODO: Apply to music bus when implemented


func _on_sfx_volume_changed(value: float) -> void:
	sfx_volume_label.text = str(int(value)) + "%"
	# TODO: Apply to SFX bus when implemented


func _update_volume_labels() -> void:
	master_volume_label.text = str(int(master_volume_slider.value)) + "%"
	music_volume_label.text = str(int(music_volume_slider.value)) + "%"
	sfx_volume_label.text = str(int(sfx_volume_slider.value)) + "%"


func _on_back_pressed() -> void:
	# Return to main menu
	SceneManager.goto_scene("res://game/scenes/menus/main_menu.tscn")


func _process(_delta: float) -> void:
	# ESC also goes back
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()
