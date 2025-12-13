## InputManager Usage Examples
## This file demonstrates how to use InputManager in combat and movement systems

class_name InputManagerExample
extends Node

# Example: Combat system checking for buffered attacks
func check_attack_input(player_id: int) -> bool:
	## Returns true if player pressed attack button within buffer window
	## Use this for attack startup frames - allows player input during previous action
	return InputManager.get_buffered_input(player_id, "attack")


# Example: Consuming attack input to prevent double-triggers
func try_execute_attack(player_id: int) -> bool:
	## Consumes attack input and executes attack if found
	## Returns true only once per button press within buffer window
	if InputManager.consume_buffered_input(player_id, "attack"):
		print("Player %d attack executed" % player_id)
		return true
	return false


# Example: Movement based on held keys (not buffered)
func update_movement(player_id: int) -> Vector2:
	## Get movement direction based on currently held inputs
	## Returns normalized direction vector
	var movement = InputManager.get_movement_input(player_id)
	print("Player %d moving: %s" % [player_id, movement])
	return movement


# Example: Complex input sequence detection
func check_special_move_input(player_id: int) -> bool:
	## Example of checking for a special move
	## This would be expanded with actual combo detection logic

	# Check if special button was pressed
	if InputManager.get_buffered_input(player_id, "special"):
		# Could add directional requirements here
		var movement = InputManager.get_movement_input(player_id)
		print("Special move detected for player %d with direction %s" % [player_id, movement])
		return true

	return false


# Example: Debug output
func print_buffer_state() -> void:
	## Print current input buffer state for debugging
	var status = InputManager.get_buffer_status()
	print("Input Buffer Status:")
	print("  Current frame: %d" % status["current_frame"])
	print("  Buffer size: %d / %d frames" % [status["buffer_size"], status["buffer_frames"]])
	for entry in status["entries"]:
		print("    Player %d: %s (frame %d, consumed: %s)" % [
			entry["player_id"],
			entry["action"],
			entry["frame_pressed"],
			entry["consumed"]
		])


# Example integration in a character controller
func example_character_controller() -> void:
	## This shows how InputManager would be used in actual game code

	for player_id in [1, 2]:
		# Check for attack input (buffered - forgiving)
		if InputManager.get_buffered_input(player_id, "attack"):
			# Character is in correct state to perform attack
			# Try to consume the input
			if InputManager.consume_buffered_input(player_id, "attack"):
				print("Starting attack animation for player %d" % player_id)

		# Check for movement input (continuous - real-time)
		var movement = InputManager.get_movement_input(player_id)
		if movement != Vector2.ZERO:
			# Apply movement
			print("Moving player %d: %s" % [player_id, movement])
