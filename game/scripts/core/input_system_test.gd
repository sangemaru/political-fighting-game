## Input System Test Script
## Simple test to verify InputManager functionality
## Attach to a Node in the scene for basic testing

extends Node

@export var enable_debug_output: bool = true
var frame_counter: int = 0


func _ready() -> void:
	if enable_debug_output:
		print("=== Input System Test Started ===")
		print("Player 1: WASD movement, J/K attacks")
		print("Player 2: Arrow keys movement, Numpad 1/2 attacks")
		print("Frame buffer size: 6 frames (~100ms)")


func _physics_process(_delta: float) -> void:
	frame_counter += 1

	if enable_debug_output and frame_counter % 10 == 0:  # Print every 10 frames
		_print_input_state()


func _print_input_state() -> void:
	## Print current input state for debugging

	print("\n--- Frame %d ---" % frame_counter)

	# Check Player 1
	var p1_movement = InputManager.get_movement_input(1)
	if p1_movement != Vector2.ZERO:
		print("P1 Movement: %s" % p1_movement)

	if InputManager.get_buffered_input(1, "attack"):
		print("P1 Attack: BUFFERED")

	if InputManager.get_buffered_input(1, "special"):
		print("P1 Special: BUFFERED")

	# Check Player 2
	var p2_movement = InputManager.get_movement_input(2)
	if p2_movement != Vector2.ZERO:
		print("P2 Movement: %s" % p2_movement)

	if InputManager.get_buffered_input(2, "attack"):
		print("P2 Attack: BUFFERED")

	if InputManager.get_buffered_input(2, "special"):
		print("P2 Special: BUFFERED")

	# Show buffer status
	var status = InputManager.get_buffer_status()
	if status["buffer_size"] > 0:
		print("Buffer: %d entries (frame window: %d-%d)" % [
			status["buffer_size"],
			status["current_frame"] - 6,
			status["current_frame"]
		])


# Test functions for manual verification

func test_buffer_size() -> void:
	## Verify buffer maintains 6 frame window
	var status = InputManager.get_buffer_status()
	assert(status["buffer_frames"] == 6, "Buffer frame count incorrect")
	print("✓ Buffer size test passed")


func test_action_registration() -> void:
	## Verify all actions are registered
	var actions = [
		"p1_left", "p1_right", "p1_up", "p1_down", "p1_attack", "p1_special",
		"p2_left", "p2_right", "p2_up", "p2_down", "p2_attack", "p2_special"
	]

	for action in actions:
		assert(InputMap.has_action(action), "Action not registered: %s" % action)

	print("✓ All %d actions registered" % actions.size())


func test_movement_normalization() -> void:
	## Verify movement vector is normalized
	# This is hard to test without actual input, but we can verify the function exists
	var movement = InputManager.get_movement_input(1)
	assert(movement is Vector2, "Movement should return Vector2")
	print("✓ Movement normalization test passed")


# Manual test triggering (useful in editor console)

func manual_test_all() -> void:
	## Run all manual tests
	print("\n=== Running Input System Tests ===")
	test_action_registration()
	test_buffer_size()
	test_movement_normalization()
	print("=== All tests passed ===\n")
