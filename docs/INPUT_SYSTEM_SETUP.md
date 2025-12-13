# Input System Setup Guide

## Overview
The input system consists of three core components:
1. **InputManager** - Singleton autoload handling all input polling and buffering
2. **Input Actions** - Action definitions for both players
3. **Input Buffer** - 6-frame buffer for fighting game responsiveness

## Files Created

### Core Files
- `game/scripts/core/input_manager.gd` - Main InputManager singleton
- `game/scripts/core/input_actions.gd` - Input action definitions and documentation
- `game/scripts/core/input_manager_example.gd` - Usage examples

## Setup Instructions

### Step 1: Register InputManager as Autoload

1. Open Godot Editor
2. Go to **Project > Project Settings > Autoload**
3. Add new autoload:
   - **Path**: `res://game/scripts/core/input_manager.gd`
   - **Name**: `InputManager`
   - Click **Add**

The InputManager will now be globally available as `InputManager` singleton.

### Step 2: Input Action Setup (Two Options)

#### Option A: Runtime Registration (Recommended for Development)
The InputManager automatically registers all actions on `_ready()`. No additional setup needed.

#### Option B: Project.godot Configuration (Production)
1. Open `project.godot` in a text editor
2. Add the input definitions from `input_actions.gd` to the `[input]` section
3. This pre-defines actions in the editor

## Input Mappings

### Player 1 (WASD + JKL)
| Input | Key | Action |
|-------|-----|--------|
| Move Left | A | `p1_left` |
| Move Right | D | `p1_right` |
| Move Up | W | `p1_up` |
| Move Down | S | `p1_down` |
| Attack | J | `p1_attack` |
| Special | K | `p1_special` |

### Player 2 (Arrow Keys + Numpad)
| Input | Key | Action |
|-------|-----|--------|
| Move Left | Left Arrow | `p2_left` |
| Move Right | Right Arrow | `p2_right` |
| Move Up | Up Arrow | `p2_up` |
| Move Down | Down Arrow | `p2_down` |
| Attack | Numpad 1 | `p2_attack` |
| Special | Numpad 2 | `p2_special` |

## API Reference

### Input Checking Methods

#### `get_buffered_input(player_id: int, action: String) -> bool`
Check if action was pressed within buffer window. Non-destructive read.
```gdscript
if InputManager.get_buffered_input(1, "attack"):
    print("Player 1 pressed attack")
```

#### `consume_buffered_input(player_id: int, action: String) -> bool`
Check and mark input as consumed. Returns true only once per press.
```gdscript
if InputManager.consume_buffered_input(1, "attack"):
    # Execute attack - called only once per button press
    player.perform_attack()
```

#### `get_current_input(player_id: int, action: String) -> bool`
Get current held state (not buffered). Useful for continuous actions.
```gdscript
if InputManager.get_current_input(1, "move_left"):
    # Player 1 is currently holding left
    player.velocity.x = -speed
```

#### `get_movement_input(player_id: int) -> Vector2`
Convenience method to get normalized movement vector.
```gdscript
var direction = InputManager.get_movement_input(1)
player.velocity = direction * speed
```

### Buffer Management Methods

#### `get_buffer_status() -> Dictionary`
Debug function returning current buffer state.
```gdscript
var status = InputManager.get_buffer_status()
print("Frame: %d, Buffer size: %d" % [status["current_frame"], status["buffer_size"]])
```

#### `clear_buffer() -> void`
Clear all buffered inputs. Useful for scene transitions.
```gdscript
InputManager.clear_buffer()
```

## Implementation Details

### Buffer System
- **Buffer size**: 6 frames (~100ms at 60fps)
- **Frame counter**: Incremented every physics frame in `_physics_process()`
- **Input checking**: Only returns inputs within current frame - (BUFFER_FRAMES)

### Determinism
- No `randf()` or frame-based randomness
- Frame counter is deterministic (increments by 1 each physics frame)
- Input timing is exact frame number
- Suitable for network replication and replay

### Performance
- Single pass per frame during `_physics_process()`
- Automatic cleanup of old buffer entries
- O(n) lookup where n = buffered inputs (typically 0-6)

## Usage Examples

### Basic Movement
```gdscript
extends CharacterBody2D

@export var speed: float = 200.0

func _physics_process(_delta: float) -> void:
    var direction = InputManager.get_movement_input(1)
    velocity = direction * speed
    move_and_slide()
```

### Attack with Buffer
```gdscript
extends Node

var is_attacking: bool = false

func _physics_process(_delta: float) -> void:
    if InputManager.get_buffered_input(1, "attack") and not is_attacking:
        if InputManager.consume_buffered_input(1, "attack"):
            start_attack()

func start_attack() -> void:
    is_attacking = true
    # Animation/damage code here
```

### Combo Detection
```gdscript
func check_for_combo() -> String:
    # Check if special was pressed
    if InputManager.consume_buffered_input(1, "special"):
        # Check current movement for direction
        var movement = InputManager.get_movement_input(1)

        if movement.x > 0.5:
            return "special_forward"
        elif movement.x < -0.5:
            return "special_back"
        else:
            return "special_neutral"

    return ""
```

## Future Enhancements

- Gamepad support (mapping controller buttons)
- Customizable input rebinding
- Input replay/recording system
- Advanced combo detection
- Input prediction for network play
- Motion input detection (hadoken-style inputs)

## Troubleshooting

### Actions not registering?
- Ensure InputManager autoload is enabled in Project Settings
- Check that `_ready()` has been called
- Verify action names match exactly (case-sensitive)

### Buffer not working?
- Ensure using `_physics_process()` for game logic (deterministic)
- Don't use `_process()` for physics/input-dependent code
- Check `get_buffer_status()` to verify buffer is populated

### Input feels unresponsive?
- BUFFER_FRAMES=6 is optimized for 60fps
- For 30fps, reduce to BUFFER_FRAMES=3
- For 120fps, increase to BUFFER_FRAMES=12
