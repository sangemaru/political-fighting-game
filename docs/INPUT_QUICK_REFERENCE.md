# Input System Quick Reference

## Setup (One-time)
1. Project Settings → Autoload
2. Add: `res://game/scripts/core/input_manager.gd` as "InputManager"

## Usage Patterns

### Get Player Movement
```gdscript
var direction = InputManager.get_movement_input(1)  # Player 1
velocity = direction * speed
```

### Check for Attack (Buffered - Forgiving)
```gdscript
if InputManager.get_buffered_input(1, "attack"):
    # Attack button pressed within last 6 frames
    execute_attack()
```

### Consume Attack (Once per Press)
```gdscript
if InputManager.consume_buffered_input(1, "attack"):
    # Called only once per button press
    character.perform_attack()
```

### Check Held Input (Continuous)
```gdscript
if InputManager.get_current_input(1, "attack"):
    # Attack button currently held down
    charge_attack()
```

## Input Actions
- Player 1: `p1_left`, `p1_right`, `p1_up`, `p1_down`, `p1_attack`, `p1_special`
- Player 2: `p2_left`, `p2_right`, `p2_up`, `p2_down`, `p2_attack`, `p2_special`

## Key Mappings

**Player 1**
- WASD: Movement
- J: Attack
- K: Special

**Player 2**
- Arrow Keys: Movement
- Numpad 1: Attack
- Numpad 2: Special

## Common Mistakes

❌ Using `_process()` with input
```gdscript
func _process(delta):
    # WRONG - not synchronized with input buffer
    if InputManager.get_buffered_input(1, "attack"):
        pass
```

✓ Use `_physics_process()` instead
```gdscript
func _physics_process(_delta):
    # RIGHT - frame-synchronized
    if InputManager.get_buffered_input(1, "attack"):
        pass
```

## Buffer Details
- **Size**: 6 frames (~100 milliseconds at 60fps)
- **Type**: Circular, auto-cleaning
- **Usage**: Forgiving input window for fighting game feel

## Debugging
```gdscript
# Print buffer state
var status = InputManager.get_buffer_status()
print(status)

# Clear buffer (e.g., on scene transition)
InputManager.clear_buffer()
```

## Files
- **Main**: `game/scripts/core/input_manager.gd`
- **Docs**: `docs/INPUT_SYSTEM_SETUP.md`
- **Examples**: `game/scripts/core/input_manager_example.gd`
