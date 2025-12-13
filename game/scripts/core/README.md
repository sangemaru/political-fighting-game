# Game State Management System

## Overview
This directory contains the core state management infrastructure for the political fighting game:
- **GameManager**: Global game state and game flow
- **StateMachine**: Reusable generic state machine
- **BattleStateMachine**: Battle-specific state management with timers
- **SceneManager**: Scene transition and preloading

## Files

### game_manager.gd
**Purpose**: Global singleton managing overall game flow

**Game States**:
- `MENU` - Main menu
- `CHARACTER_SELECT` - Character selection screen
- `BATTLE` - Active round gameplay
- `PAUSE` - Game paused
- `ROUND_END` - Round finished, waiting for next
- `MATCH_END` - Match finished (best of 3 rounds)

**Key Methods**:
- `change_state(new_state: int)` - Change game state
- `toggle_pause()` - Pause/unpause during battle
- `is_round_time_up()` - Check if round duration exceeded
- `get_round_remaining_time()` - Get remaining seconds in round
- `get_round_remaining_frames()` - Get remaining frames (deterministic)
- `start_new_round()` - Prepare next round
- `reset_battle()` - Reset all battle state

**Signals**:
- `state_changed(old_state, new_state)`
- `battle_started`
- `battle_ended`
- `round_started(round_number)`
- `round_ended(winner)`
- `match_ended(winner)`
- `pause_toggled(is_paused)`

**Configuration**:
- `round_duration_seconds` - How long each round lasts (default: 99 seconds)
- `max_rounds` - Number of rounds for match (default: 3 = best of 3)

**Autoload Setup** (Required):
In Project Settings > Autoload, add this with name "GameManager":
```
Path: res://game/scripts/core/game_manager.gd
Node Name: GameManager
```

### state_machine.gd
**Purpose**: Generic reusable state machine (for game states, character states, etc.)

**Key Methods**:
- `add_state(state_name, state_obj)` - Register a state
- `change_state(new_state)` - Transition to state
- `get_current_state()` - Get current state object
- `process_state(delta)` - Process current state
- `physics_process_state(delta)` - Physics process current state

**State Virtual Methods** (implement in state classes):
- `_enter_state()` - Called on state entry
- `_exit_state()` - Called on state exit
- `_process_state(delta)` - Called each frame
- `_physics_process_state(delta)` - Called each physics frame

### battle_state_machine.gd
**Purpose**: Specialized state machine for battle rounds with timers and win conditions

**Battle States**:
- `INITIALIZING` - Setting up round
- `ROUND_ACTIVE` - Round in progress
- `ROUND_PAUSED` - Round paused
- `ROUND_ENDED` - Round finished
- `MATCH_ENDED` - Match finished (best of 3)

**Key Methods**:
- `initialize(player1, player2)` - Start battle with players
- `start_round()` - Begin a round
- `check_round_end_conditions()` - Check for KO or timeout
- `end_round(winner, reason)` - Finish round (updates match score)
- `pause_round()` - Pause round timer
- `resume_round()` - Resume round timer
- `get_remaining_time()` - Seconds remaining (float)
- `get_remaining_time_formatted()` - String format "MM:SS"

**Signals**:
- `round_started`
- `round_ended(winner, reason)`
- `match_ended(winner)`
- `time_warning` - Emitted at 10 seconds remaining
- `round_time_up` - Emitted when time expires

**Configuration**:
- `round_duration_frames` - Length of round in frames (5940 = 99 sec @ 60 FPS)
- `max_rounds` - Rounds per match (3 = best of 3)
- `ko_threshold` - Health value at which KO occurs (0.0 = any <= 0)

**Win Conditions**:
1. **KO**: Player health drops to/below 0
2. **Timeout**: Time reaches 0, winner determined by remaining health
3. **Draw**: Both players have equal health at timeout

**Deterministic Timing**:
- Uses frame counting instead of delta time
- Automatically advances `round_elapsed_frames` each physics frame
- Assumes 60 FPS (adjustable via frame constants)

### scene_manager.gd
**Purpose**: Handle scene transitions with fade effects and preloading

**Key Methods**:
- `goto_scene(scene_path, use_fade)` - Transition to new scene
- `reload_current_scene(use_fade)` - Reload current scene
- `preload_scene(scene_path)` - Preload scene for faster access
- `preload_scenes(scene_paths)` - Preload multiple scenes
- `is_transitioning()` - Check if transition in progress
- `get_current_scene()` - Get active scene node

**Features**:
- Fade in/out animations
- Configurable fade duration (`fade_duration` = 0.5 seconds)
- Caches preloaded scenes
- Prevents overlapping transitions

**Autoload Setup** (Optional):
In Project Settings > Autoload, add this with name "SceneManager":
```
Path: res://game/scripts/core/scene_manager.gd
Node Name: SceneManager
```

## Game Flow Example

```gdscript
# Start from menu
GameManager.change_state(GameManager.GameState.MENU)

# Transition to character select
GameManager.change_state(GameManager.GameState.CHARACTER_SELECT)

# Start battle
GameManager.change_state(GameManager.GameState.BATTLE)

# Pause during battle
GameManager.toggle_pause()  # Changes to PAUSE state

# Resume
GameManager.toggle_pause()  # Returns to BATTLE state

# End round (checks win conditions)
if battle_sm.check_round_end_conditions() == "player1":
    battle_sm.end_round("player1", "KO")

# Check remaining time
print(GameManager.get_round_remaining_time())  # Seconds
print(GameManager.get_round_remaining_frames())  # Frames (deterministic)
```

## Integration Checklist

- [ ] Add GameManager to Autoload (Project Settings > Autoload)
- [ ] Add SceneManager to Autoload (optional, if using scene transitions)
- [ ] Create player character classes with `health` property
- [ ] Create scene for battle arena with player spawn points
- [ ] Create pause menu UI (respond to `pause_toggled` signal)
- [ ] Create round UI (show timer via `get_round_remaining_time_formatted()`)
- [ ] Connect battle signals to UI updates
- [ ] Test round timer with `check_round_end_conditions()`
- [ ] Verify deterministic frame counting (no delta time dependencies)

## Testing

### Test Round Timer
```gdscript
func test_round_timer():
    var gm = GameManager
    gm.change_state(GameManager.GameState.BATTLE)

    # Advance one frame
    await get_tree().process_frame
    assert(gm.battle_frame == 1)

    # Check remaining time
    var remaining = gm.get_round_remaining_time()
    assert(remaining < 99.0 and remaining > 98.9)  # ~98.98 seconds
```

### Test Win Conditions
```gdscript
func test_ko_condition():
    var battle_sm = BattleStateMachine.new()
    add_child(battle_sm)

    # Create mock players
    var p1 = Node.new()
    p1.health = 100.0
    var p2 = Node.new()
    p2.health = 0.0  # KO'd

    battle_sm.initialize(p1, p2)
    var winner = battle_sm.check_round_end_conditions()
    assert(winner == "player1")
```

## Notes

- **Deterministic**: All timers use frame counting, NOT delta time
- **Signals**: Use signals for loose coupling between systems
- **Enum States**: States are integers (enums), not strings, for performance
- **Best of 3**: Match ends when a player wins 2 rounds
- **Timeout Winner**: Determined by higher remaining health
