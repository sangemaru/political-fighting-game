extends Control

@onready var action_list = $Panel/MarginContainer/VBoxContainer/ScrollContainer/ActionList
@onready var back_button = $Panel/MarginContainer/VBoxContainer/BackButton
@onready var rebind_popup = $RebindPopup
@onready var rebind_label = $RebindPopup/MarginContainer/VBoxContainer/Label

var waiting_for_input = false
var current_action = ""
var current_event_index = 0

# All actions we want to allow rebinding
var rebindable_actions = [
	"p1_move_left", "p1_move_right", "p1_move_up", "p1_move_down",
	"p1_attack", "p1_special",
	"p2_move_left", "p2_move_right", "p2_move_up", "p2_move_down",
	"p2_attack", "p2_special"
]

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	rebind_popup.hide()
	_populate_action_list()

func _populate_action_list():
	# Clear existing children
	for child in action_list.get_children():
		child.queue_free()

	# Create entry for each action
	for action in rebindable_actions:
		var hbox = HBoxContainer.new()
		hbox.set_h_size_flags(Control.SIZE_EXPAND_FILL)

		# Action label
		var action_label = Label.new()
		action_label.text = _get_action_display_name(action)
		action_label.set_h_size_flags(Control.SIZE_EXPAND_FILL)
		hbox.add_child(action_label)

		# Get events for this action
		var events = InputMap.action_get_events(action)
		for i in range(events.size()):
			var event = events[i]
			var button = Button.new()
			button.text = _get_event_display_name(event)
			button.custom_minimum_size = Vector2(150, 0)
			button.pressed.connect(_on_rebind_button_pressed.bind(action, i))
			hbox.add_child(button)

		action_list.add_child(hbox)

func _get_action_display_name(action: String) -> String:
	var parts = action.split("_")
	var player = parts[0].to_upper()
	var rest = " ".join(parts.slice(1))
	return player + " " + rest.capitalize()

func _get_event_display_name(event: InputEvent) -> String:
	if event is InputEventKey:
		return OS.get_keycode_string(event.keycode)
	elif event is InputEventJoypadButton:
		return "Joy " + str(event.device) + " Btn " + str(event.button_index)
	elif event is InputEventJoypadMotion:
		var axis_name = ""
		match event.axis:
			JOY_AXIS_LEFT_X:
				axis_name = "L-Stick X"
			JOY_AXIS_LEFT_Y:
				axis_name = "L-Stick Y"
			JOY_AXIS_RIGHT_X:
				axis_name = "R-Stick X"
			JOY_AXIS_RIGHT_Y:
				axis_name = "R-Stick Y"
			_:
				axis_name = "Axis " + str(event.axis)
		var direction = "+" if event.axis_value > 0 else "-"
		return "Joy " + str(event.device) + " " + axis_name + direction
	else:
		return "Unknown"

func _on_rebind_button_pressed(action: String, event_index: int):
	current_action = action
	current_event_index = event_index
	waiting_for_input = true
	rebind_label.text = "Press any key or button...\n(ESC to cancel)"
	rebind_popup.show()

func _input(event):
	if not waiting_for_input:
		return

	# Cancel on ESC
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_cancel_rebind()
		return

	# Accept keyboard or joypad input
	if (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion) and event.is_pressed():
		_apply_rebind(event)

func _apply_rebind(new_event: InputEvent):
	# Get current events
	var events = InputMap.action_get_events(current_action)

	# Replace the event at the specified index
	if current_event_index < events.size():
		InputMap.action_erase_event(current_action, events[current_event_index])

	# Add the new event
	InputMap.action_add_event(current_action, new_event)

	# Save to settings
	_save_input_mappings()

	# Refresh display
	_populate_action_list()

	# Close popup
	_cancel_rebind()

func _cancel_rebind():
	waiting_for_input = false
	current_action = ""
	current_event_index = 0
	rebind_popup.hide()

func _save_input_mappings():
	# Save all custom input mappings to settings
	for action in rebindable_actions:
		var events = InputMap.action_get_events(action)
		var event_data = []
		for event in events:
			event_data.append(_serialize_event(event))
		SettingsManager.set_setting("input", action, event_data)

func _serialize_event(event: InputEvent) -> Dictionary:
	var data = {}
	if event is InputEventKey:
		data["type"] = "key"
		data["keycode"] = event.keycode
	elif event is InputEventJoypadButton:
		data["type"] = "joypad_button"
		data["device"] = event.device
		data["button_index"] = event.button_index
	elif event is InputEventJoypadMotion:
		data["type"] = "joypad_motion"
		data["device"] = event.device
		data["axis"] = event.axis
		data["axis_value"] = event.axis_value
	return data

func _on_back_pressed():
	SceneManager.load_scene("res://game/scenes/menus/options_menu.tscn")
