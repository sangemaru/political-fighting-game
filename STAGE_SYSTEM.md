# Stage System Documentation

## Overview

The stage system provides a framework for creating and managing battle arenas in the political fighting game. It includes:

- **F36**: Base stage class with collision setup and boundary management
- **F37**: JSON schema defining stage data format
- **F38**: First playable stage "The Arena"

## Architecture

### File Structure

```
game/
├── scripts/stages/
│   ├── base_stage.gd          # Base class for all stages
│   └── stage_loader.gd        # Stage loading utility
├── resources/stages/
│   └── arena_1.json           # Stage 1 configuration data
├── resources/schemas/
│   └── stage_schema.json      # JSON schema validation
└── scenes/stages/
    └── arena_1.tscn           # Stage 1 scene (Godot format)
```

## Components

### F36: Base Stage Class (`base_stage.gd`)

The `BaseStage` class extends `Node2D` and provides:

**Properties:**
- `stage_name`: Display name for the stage
- `stage_id`: Unique identifier
- `boundaries`: Dictionary with left, right, top, bottom coordinates
- `spawn_points`: Dictionary with player_1 and player_2 spawn positions
- `camera_limits`: Camera boundary constraints

**Methods:**
- `load_from_resource(path)`: Load stage data from JSON file
- `get_spawn_position(player_id)`: Get spawn position for a player
- `is_in_bounds(position)`: Check if position is within stage
- `get_stage_center()`: Get center point of stage
- `get_stage_width()`: Get stage width
- `get_stage_height()`: Get stage height

**Collision Setup:**
- Ground: StaticBody2D with RectangleShape2D at bottom
- Left Wall: StaticBody2D at left boundary (x=50)
- Right Wall: StaticBody2D at right boundary (x=1230)
- Background: ColorRect for visual appearance

### F37: Stage Schema (`stage_schema.json`)

JSON Schema that defines the structure of stage data files. Required properties:

```json
{
  "id": "string",              // Unique stage identifier
  "name": "string",            // Display name
  "description": "string",     // Stage background/lore
  "boundaries": {
    "left": number,            // Left boundary X
    "right": number,           // Right boundary X
    "top": number,             // Top boundary Y
    "bottom": number           // Ground/bottom boundary Y
  },
  "spawn_points": {
    "player_1": { "x": number, "y": number },
    "player_2": { "x": number, "y": number }
  },
  "camera": {
    "enabled": boolean,        // Follow action or fixed
    "limit_left": number,
    "limit_right": number,
    "limit_top": number,
    "limit_bottom": number
  },
  "hazards": [                 // Optional, empty for MVP
    {
      "id": "string",
      "type": "spike|fire|moving_platform|custom",
      "position": { "x": number, "y": number },
      "size": { "width": number, "height": number },
      "damage": number          // Optional
    }
  ]
}
```

### F38: Arena 1 Stage (`arena_1.tscn` + `arena_1.json`)

**Scene File (arena_1.tscn):**
- Godot scene with Arena1 node extending BaseStage
- Background ColorRect (dark gray) filling viewport
- Size: 1280x720

**Configuration (arena_1.json):**
```json
{
  "id": "arena_1",
  "name": "The Arena",
  "boundaries": {
    "left": 50,
    "right": 1230,
    "top": 0,
    "bottom": 650
  },
  "spawn_points": {
    "player_1": { "x": 320, "y": 650 },    // 25% width from left
    "player_2": { "x": 960, "y": 650 }     // 75% width from left
  },
  "camera": {
    "enabled": false,                       // Fixed camera (MVP)
    "limit_left": 0,
    "limit_right": 1280,
    "limit_top": 0,
    "limit_bottom": 720
  },
  "hazards": []                             // No hazards for MVP
}
```

## Stage Layout Diagram

```
┌─────────────────────────────────────────┐ Y=0
│         STAGE VIEWPORT (1280x720)      │
│                                         │
│ [WALL X=50]              [WALL X=1230] │
│   │                           │         │
│   │   P1 (320,650)  P2 (960,650)      │
│   │      ●                  ●          │
│  ═════════════════════════════════════  Y=650 (Ground)
│  └─────────────────────────────────────┘
└─────────────────────────────────────────┘
 X=0                                   X=1280
```

**Key Coordinates:**
- Viewport: 1280 x 720 pixels
- Left Wall: X = 50 (invisible collision)
- Right Wall: X = 1230 (invisible collision)
- Ground: Y = 650 (20px thick StaticBody2D)
- Player 1 Spawn: (320, 650) - 25% from left
- Player 2 Spawn: (960, 650) - 75% from left
- Playable Width: 1180 pixels (50→1230)
- Playable Height: 650 pixels (0→650)

## Usage

### Loading a Stage

```gdscript
# Method 1: Using StageLoader
var stage = StageLoader.load_stage("arena_1")
add_child(stage)

# Method 2: Direct instantiation
var stage_scene = load("res://scenes/stages/arena_1.tscn")
var stage = stage_scene.instantiate()
stage.load_from_resource("res://resources/stages/arena_1.json")
add_child(stage)
```

### Getting Spawn Positions

```gdscript
var p1_spawn = stage.get_spawn_position(1)  # Returns Vector2(320, 650)
var p2_spawn = stage.get_spawn_position(2)  # Returns Vector2(960, 650)
```

### Checking Boundaries

```gdscript
var is_valid = stage.is_in_bounds(Vector2(640, 400))  # true
var is_out = stage.is_in_bounds(Vector2(0, 0))        # false (outside left wall)
```

### Stage Dimensions

```gdscript
var width = stage.get_stage_width()    # 1180
var height = stage.get_stage_height()  # 650
var center = stage.get_stage_center()  # Vector2(640, 325)
```

## Signals

- `stage_loaded(stage_id)`: Emitted when stage finishes loading
- `player_out_of_bounds(player_id)`: Emitted when player exceeds boundaries (not yet implemented)

## Collision Layers

Stages use Godot's collision system:
- **Layer 1**: Characters (BaseFighter uses this)
- **Static bodies**: Ground and walls for character collisions
- Characters can collide with ground and walls automatically

## Future Expansion

The stage system is designed for expansion:

1. **Hazards**: JSON schema supports spike, fire, moving_platform types
2. **Camera Follow**: Set `camera.enabled: true` for dynamic camera
3. **Multi-Platform**: Add moving platforms via hazards array
4. **Stage Transitions**: Animation support for stage changes
5. **Interactive Elements**: Background hazards with damage

## Testing

To test the stage system:

1. Create a test scene with a stage
2. Instantiate the stage and add it to the scene
3. Add characters to the stage at spawn positions
4. Verify collision detection with walls and ground
5. Verify spawn point positions match layout

## Compatibility

- **Godot Version**: 4.x
- **Physics**: CharacterBody2D for actors, StaticBody2D for stage
- **Collision**: Uses standard Godot collision shapes
- **Resolution**: Built for 1280x720 viewport

## Status

- ✅ F36: Base stage class complete
- ✅ F37: Stage schema defined
- ✅ F38: Arena 1 stage created
- ✅ Collision setup (ground + walls)
- ✅ Spawn point configuration
- ❌ Hazard implementation (deferred for future release)
- ❌ Camera follow (deferred, set to fixed for MVP)
