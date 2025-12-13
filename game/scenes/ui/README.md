# Battle UI System

Complete battle UI implementation including health bars, HUD, timers, and end screens.

## Components Overview

### Health Bar (F31)
- **Script**: `game/scripts/ui/health_bar.gd`
- **Scene**: `game/scenes/ui/health_bar.tscn`
- Shows current health / max health with smooth animation
- Animates when damage is taken (displays target health)
- Damage bar shows delayed health reduction (catch-up animation)
- Color-coded: Blue for P1, Red for P2
- Connects to fighter's `health_changed` and `died` signals

**Key Methods**:
- `connect_to_fighter(fighter)` - Attach to fighter and listen to health changes
- `set_health(health)` - Manually update displayed health (testing)
- `get_displayed_health()` - Get current animated value
- `get_target_health()` - Get actual fighter health

### Round Timer (F33)
- **Script**: `game/scripts/ui/round_timer.gd`
- **Scene**: `game/scenes/ui/round_timer.tscn`
- Shows remaining time in seconds (99, 98, 97...)
- Centered at top of screen
- Flashes red when under 10 seconds
- Reads from GameManager's `get_round_remaining_time()`

**Key Methods**:
- `set_remaining_time(seconds)` - Manually set time (testing)
- `get_displayed_time()` - Get current displayed seconds

### Player HUD (F32)
- **Script**: `game/scripts/ui/player_hud.gd`
- **Scene**: `game/scenes/ui/player_hud.tscn`
- Contains: health bar, player name, round wins indicator, portrait placeholder
- Positioned at top corners (P1 left, P2 right)
- Shows round wins as yellow dots

**Key Methods**:
- `connect_to_fighter(fighter)` - Attach to fighter
- `set_character_name(name)` - Update character display name
- `add_round_win()` - Increment round wins
- `reset_round_wins()` - Clear round wins for new match
- `get_health_bar()` - Access health bar component

### Round End Overlay (F34)
- **Script**: `game/scripts/ui/round_end_overlay.gd`
- **Scene**: `game/scenes/ui/round_end_overlay.tscn`
- Shows "PLAYER 1 WINS!" or "PLAYER 2 WINS!"
- Shows "K.O." or "TIME!" depending on win condition
- Shows round score
- Auto-hides after 3 seconds
- Emits `overlay_finished` signal when done

**Key Methods**:
- `show_overlay(winner, condition, p1_wins, p2_wins)` - Display with all info
- `set_win_condition(condition)` - Update condition text
- `hide_overlay()` - Hide immediately

### Match End Screen (F35)
- **Script**: `game/scripts/ui/match_end_screen.gd`
- **Scene**: `game/scenes/ui/match_end_screen.tscn`
- Shows final winner
- Options: "Rematch" and "Main Menu" buttons
- Simple button navigation
- Emits `rematch_requested` or `main_menu_requested` signals

**Key Methods**:
- `show_screen(winner)` - Display match end screen
- `hide_screen()` - Hide screen

### Battle HUD Manager (Coordinator)
- **Script**: `game/scripts/ui/battle_hud_manager.gd`
- **Scene**: `game/scenes/ui/battle_hud.tscn`
- Coordinates all UI elements during battle
- Tracks round wins for both players
- Handles transitions between round and match states
- Listens to GameManager signals and fighter death events

**Key Methods**:
- `initialize_battle(p1, p2)` - Setup HUD with fighters
- `get_player_hud(player_id)` - Get HUD for player
- `get_round_wins(player_id)` - Get player's round wins

## Signal Connections

### From BaseFighter
```gdscript
fighter.health_changed.connect(_on_health_changed)  # HealthBar listens
fighter.died.connect(_on_fighter_died)              # HealthBar listens
```

### From GameManager
```gdscript
GameManager.battle_started.connect(_on_battle_started)
GameManager.round_started.connect(_on_round_started)
GameManager.round_ended.connect(_on_round_ended)
GameManager.match_ended.connect(_on_match_ended)
```

## Integration in Battle Scene

Add to your battle scene:

```gdscript
# In your battle setup
var battle_hud = preload("res://game/scenes/ui/battle_hud.tscn").instantiate()
add_child(battle_hud)

# Connect fighters
battle_hud.initialize_battle(player1_fighter, player2_fighter)
```

## Layout Structure

```
┌─────────────────────────────────────────────────────────────────┐
│ [P1 Health: 100/100] [99] [100/100 Health: P2]                 │
│ [P1 Name] ○            [P2 Name] ○                              │
│                                                                  │
│                   (Battle Area - 1280x720)                      │
│                                                                  │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│ Overlay (when round ends):                                       │
│           PLAYER 1 WINS!                                         │
│              K.O.                                                │
│           Round Score: 2 - 1                                     │
└─────────────────────────────────────────────────────────────────┘
```

## Testing Checklist

- [ ] Health bars animate smoothly when damage taken
- [ ] Colors are correct (P1 blue, P2 red)
- [ ] Round timer counts down from 99 to 0
- [ ] Timer flashes red below 10 seconds
- [ ] Round end overlay shows winner and condition
- [ ] Overlay auto-dismisses after 3 seconds
- [ ] Round wins display as yellow dots
- [ ] Match end screen shows final winner
- [ ] Rematch button resets UI
- [ ] Main menu button navigates away

## Responsive Design

- All UI elements use anchor-based positioning
- Scales with viewport size (1280x720 is baseline)
- HUDs dock to screen corners
- Timer centered horizontally
- Overlays fill viewport

## No Hardcoded Player Names

- Character names read from fighter's `get_name()` if available
- Fallback to "Player 1"/"Player 2" if method doesn't exist
- Call `set_character_name(name)` to update at runtime

## Future Enhancements

- Add placeholder character portraits (Panel with texture)
- Add sound effects for timer warnings
- Add combo counter UI
- Add move history/input display
- Animate HUD transitions between rounds
- Add visual effects for K.O. (screen shake, etc.)
