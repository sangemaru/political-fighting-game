## Options menu script
## Placeholder for game settings

extends Control

@onready var master_volume_slider: HSlider = $VBoxContainer/MasterVolumeContainer/VolumeSlider
@onready var master_volume_label: Label = $VBoxContainer/MasterVolumeContainer/ValueLabel
@onready var music_volume_slider: HSlider = $VBoxContainer/MusicVolumeContainer/VolumeSlider
@onready var music_volume_label: Label = $VBoxContainer/MusicVolumeContainer/ValueLabel
@onready var sfx_volume_slider: HSlider = $VBoxContainer/SFXVolumeContainer/VolumeSlider
@onready var sfx_volume_label: Label = $VBoxContainer/SFXVolumeContainer/ValueLabel
@onready var controls_button: Button = $VBoxContainer/ControlsButton
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	# Connect slider signals
	master_volume_slider.value_changed.connect(_on_master_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	controls_button.pressed.connect(_on_controls_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Load current volume settings from SettingsManager or AudioManager
	if SettingsManager:
		music_volume_slider.value = SettingsManager.get_music_volume() * 100.0
		sfx_volume_slider.value = SettingsManager.get_sfx_volume() * 100.0
	else:
		music_volume_slider.value = AudioManager.get_music_volume() * 100.0
		sfx_volume_slider.value = AudioManager.get_sfx_volume() * 100.0

	# Initialize values
	_update_volume_labels()

	# Focus controls button
	controls_button.grab_focus()


func _on_master_volume_changed(value: float) -> void:
	master_volume_label.text = str(int(value)) + "%"
	# Master volume affects both music and SFX
	var linear = value / 100.0
	if SettingsManager:
		SettingsManager.set_music_volume(linear)
		SettingsManager.set_sfx_volume(linear)
	else:
		AudioManager.set_music_volume(linear)
		AudioManager.set_sfx_volume(linear)


func _on_music_volume_changed(value: float) -> void:
	music_volume_label.text = str(int(value)) + "%"
	var linear = value / 100.0
	if SettingsManager:
		SettingsManager.set_music_volume(linear)
	else:
		AudioManager.set_music_volume(linear)


func _on_sfx_volume_changed(value: float) -> void:
	sfx_volume_label.text = str(int(value)) + "%"
	var linear = value / 100.0
	if SettingsManager:
		SettingsManager.set_sfx_volume(linear)
	else:
		AudioManager.set_sfx_volume(linear)
	# Play test sound
	AudioManager.play_sfx("menu_select")


func _on_controls_pressed() -> void:
	AudioManager.play_sfx("menu_select")
	SceneManager.goto_scene("res://game/scenes/menus/controls_menu.tscn")


func _update_volume_labels() -> void:
	master_volume_label.text = str(int(master_volume_slider.value)) + "%"
	music_volume_label.text = str(int(music_volume_slider.value)) + "%"
	sfx_volume_label.text = str(int(sfx_volume_slider.value)) + "%"


func _on_back_pressed() -> void:
	AudioManager.play_sfx("menu_back")
	# Return to main menu
	SceneManager.goto_scene("res://game/scenes/menus/main_menu.tscn")


func _process(_delta: float) -> void:
	# ESC also goes back
	if Input.is_action_just_pressed("ui_cancel"):
		AudioManager.play_sfx("menu_back")
		_on_back_pressed()
