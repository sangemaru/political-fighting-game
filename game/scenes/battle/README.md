# Battle Scene System (F39-F42)

## Overview

The battle scene is the main gameplay hub that integrates all combat, UI, and state management systems. It orchestrates the complete battle flow with proper signal connections and input routing.

## Features Implemented

### F39: Battle Scene Setup
- **File**: `battle.tscn` and `battle_scene.gd`
- **Responsibility**: Create and manage the complete battle scene hierarchy
- **Components**:
  - Stage loading and initialization
  - Fighters container node for character instances
  - UI canvas layer with health bars and timer
  - Scene root properly configured as Node2D

**Scene Tree Structure**:
```
Battle (Node2D) [battle_scene.gd]
├── Stage (BaseStage, loaded from JSON)
│   ├── Background
│   ├── Ground (CollisionShape2D)
│   ├── LeftWall (StaticBody2D)
│   ├── RightWall (StaticBody2D)
│   └── Camera2D
├── Fighters (Node2D)
│   ├── PLAYER_1_CHARACTER (BaseFighter instance)
│   │   ├── Sprite2D
│   │   ├── CollisionShape2D
│   │   ├── AnimationPlayer
│   │   ├── Hurtbox
│   │   └── ... (combat components)
│   └── PLAYER_2_CHARACTER (BaseFighter instance)
│       └── ... (same as P1)
└── UILayer (CanvasLayer, layer=10)
    ├── PlayerHUD_P1 (HealthBar instance)
    ├── PlayerHUD_P2 (HealthBar instance)
    └── RoundTimerContainer (Control)
        └── RoundTimer (Label)
```

### F40: Player Spawning & Character Loading
- **Responsibility**: Load character scenes from file and instantiate at correct spawn points
- **Process**:
  1. Read battle configuration JSON (`default_battle.json`)
  2. For each player in config:
     - Load character scene (e.g., `dictator_1.tscn`)
     - Instantiate the scene as BaseFighter
     - Set `player_id` (1 or 2)
     - Get spawn position from stage
     - Place fighter at spawn position
     - Add to Fighters node
  3. Initialize health bars with fighter references

**Configuration Format** (`default_battle.json`):
```json
{
  "players": {
    "player_1": {
      "character": "dictator_1",
      "spawn_point": "player_1"
    },
    "player_2": {
      "character": "demagogue_1",
      "spawn_point": "player_2"
    }
  },
  ...
}
```

**Supported Characters**:
- `dictator_1` - The Generalissimo (tank/heavy)
- `demagogue_1` - The Populist (fast/glass cannon)

### F41: Win Condition Integration
- **Responsibility**: Monitor fighter health and determine round/match winners
- **Win Conditions**:
  1. **KO Victory**: Fighter's health <= 0
     - Opponent wins immediately
     - Signal: `fighter.died` → battle manager
  2. **Timeout Victory**: Round duration expires
     - Fighter with higher health wins
     - On tie: declared "Draw"
     - Signal: `GameManager.is_round_time_up()` → `_end_round_by_timeout()`

**Signal Flow**:
```
Fighter takes damage
    ↓
fighter.health_changed.emit()
    ↓
HealthBar._on_health_changed() → Update display
    ↓
If health <= 0:
    fighter.died.emit()
        ↓
    battle_scene._on_player_died() → Round ends with winner
```

**Round End Flow**:
1. Winner determined (KO or timeout)
2. Round state set to inactive
3. `GameManager.end_round(winner_name)` called
4. GameManager transitions to ROUND_END state

### F42: Input Routing
- **Responsibility**: Route InputManager events to correct player's fighter
- **Player Input Mappings**:

**Player 1** (WASD + J/K):
- `p1_move_left` (A) → Move left
- `p1_move_right` (D) → Move right
- `p1_move_up` (W) → Jump
- `p1_move_down` (S) → Crouch/down
- `p1_attack` (J) → Light attack
- `p1_special` (K) → Special move

**Player 2** (Arrows + Numpad):
- `p2_move_left` (Left Arrow) → Move left
- `p2_move_right` (Right Arrow) → Move right
- `p2_move_up` (Up Arrow) → Jump
- `p2_move_down` (Down Arrow) → Crouch/down
- `p2_attack` (Enter) → Light attack
- `p2_special` (Right Ctrl) → Special move

**Input Processing**:
- Checked every physics frame in `_physics_process()`
- Only processes input when:
  - Battle is active (`battle_active == true`)
  - Round is active (`round_active == true`)
  - Fighter is alive (`fighter.is_alive == true`)
  - Fighter is in IDLE state (can accept input)
- Input routed to correct fighter via `player_id`

**Input Handler States**:
- **Movement Input**: Held (continuous)
  - Changes fighter state to WALKING
  - Sets `fighter.velocity.x`
  - Sets `fighter.facing_direction`

- **Jump Input**: Just pressed
  - Only processes if fighter is on floor
  - Changes state to JUMPING
  - Applies jump force: `v = sqrt(2 * g * h)`

- **Attack Input**: Just pressed
  - Changes state to ATTACKING
  - Character script handles move selection

- **Special Input**: Just pressed
  - Changes state to ATTACKING (same as attack)
  - Character script determines special move

## Signal Connections

### Fighter Signals
```
fighter.health_changed(current: int, max: int)
    → health_bar._on_health_changed()

fighter.died(player_id: int)
    → battle_scene._on_player_died()
    → health_bar._on_fighter_died()
```

### GameManager Signals
```
GameManager.battle_started()
    → battle_scene._on_battle_started()

GameManager.round_started(round_number: int)
    → battle_scene._on_round_started()
```

## Usage

### Starting a Battle
```gdscript
# In menu or character select scene
SceneManager.goto_scene("res://game/scenes/battle/battle.tscn")
```

### Custom Battle Configuration
1. Create new JSON in `game/resources/battle_configs/`
2. Set `battle_config_path` in scene inspector
3. Or use code:
```gdscript
battle_scene.battle_config_path = "res://game/resources/battle_configs/custom.json"
```

### Adding New Characters
1. Create character scene in `game/scenes/characters/[character_id].tscn`
2. Create character data in `game/resources/characters/[character_id].json`
3. Add to battle config:
```json
{
  "players": {
    "player_1": {
      "character": "your_character_id"
    }
  }
}
```

## Integration Points

### With GameManager
- Initializes battle state: `GameManager.change_state(BATTLE)`
- Resets battle data: `GameManager.reset_battle()`
- Monitors round timer: `GameManager.is_round_time_up()`
- Ends rounds: `GameManager.end_round(winner_name)`

### With BaseFighter
- Instantiates character scenes
- Connects health/death signals
- Routes input via state machine
- Monitors health for win conditions

### With BaseStage
- Loads stage scene
- Gets spawn positions
- Uses stage boundaries

### With HealthBar UI
- Connects to each fighter
- Updates on health changes
- Displays health percentage

### With InputManager
- Reads input actions via `Input.is_action_pressed()`
- Routes to correct player
- Respects input validation (state checks)

## Testing Checklist

- [ ] Battle scene loads without errors
- [ ] Both characters spawn at correct positions
- [ ] Health bars display correct initial health
- [ ] Health bars update when taking damage
- [ ] Round timer counts down correctly
- [ ] Player 1 responds to P1 inputs only
- [ ] Player 2 responds to P2 inputs only
- [ ] Fighters cannot input during hitstun/knockdown
- [ ] KO victory ends round immediately
- [ ] Timeout victory selects higher health fighter
- [ ] Round timer freezes when round ends
- [ ] GameManager state transitions correctly

## Performance Notes

- All timing is frame-based (deterministic at 60 FPS)
- Input processing in `_physics_process()` for consistency
- Signal connections prevent redundant polling
- Stage and fighters use efficient collision layers

## Known Limitations & Future Enhancements

### Current Limitations
- Input routing doesn't prevent input buffering (combos not yet implemented)
- No pause/resume functionality (planned for F43+)
- No match end screen integration (planned for F43+)
- No visual feedback for input acceptance

### Future Features
- Round/match end overlay
- Pause menu during battle
- Combo system with input buffering
- Visual hit feedback/particles
- Sound effects integration
- Character AI for single-player mode
- Spectator/replay system

## Files Created/Modified

### New Files
- `game/scenes/battle/battle.tscn` - Battle scene
- `game/scripts/battle/battle_scene.gd` - Battle manager script
- `game/resources/battle_configs/default_battle.json` - Default battle config

### Modified Files
- None (all systems properly integrated via signals)

## Git Commit
```
feat(F39-F42): Implement battle scene integration
- F39: Battle scene setup with proper hierarchy
- F40: Player spawning with character loading from JSON
- F41: Win condition integration (KO + timeout)
- F42: Input routing to correct players with state validation
```

## Status
✅ COMPLETE - All features F39-F42 implemented and integrated
