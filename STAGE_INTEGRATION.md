# Stage System Integration Guide

## Quick Start

To use the stage system in your battle scene:

### 1. Load and Add Stage to Scene

```gdscript
extends Node

func _ready():
	# Load the Arena 1 stage
	var stage = StageLoader.load_stage("arena_1")
	add_child(stage)

	# Get spawn positions for players
	var p1_spawn = stage.get_spawn_position(1)
	var p2_spawn = stage.get_spawn_position(2)

	# Create and position players
	var player_1 = create_player(1, p1_spawn)
	var player_2 = create_player(2, p2_spawn)

	stage.add_child(player_1)
	stage.add_child(player_2)
```

### 2. Stage-Aware Movement

Characters can use stage boundaries to prevent going off-screen:

```gdscript
extends BaseFighter

func _physics_process(delta):
	# ... normal movement code ...

	# Clamp position to stage boundaries
	if stage:
		var x = clamp(position.x, stage.boundaries.left, stage.boundaries.right)
		position.x = x
```

### 3. Monitor Stage Signals

```gdscript
func _ready():
	var stage = StageLoader.load_stage("arena_1")
	add_child(stage)

	# Connect to stage signals
	stage.stage_loaded.connect(_on_stage_loaded)
	stage.player_out_of_bounds.connect(_on_player_out_of_bounds)

func _on_stage_loaded(stage_id: String):
	print("Stage loaded: ", stage_id)
	# Start battle

func _on_player_out_of_bounds(player_id: int):
	print("Player %d is out of bounds!" % player_id)
	# Handle boundary violation
```

## Stage Layout Reference

### Arena 1 (The Arena)

**Dimensions:**
- Viewport: 1280 x 720 pixels
- Playable area: 1180 x 650 pixels

**Collision Elements:**
- Ground: Y = 650 (thick enough for character landing)
- Left Wall: X = 50
- Right Wall: X = 1230
- Ceiling: Y = 0

**Spawn Positions:**
- Player 1: (320, 650) - Standing on ground, 25% from left
- Player 2: (960, 650) - Standing on ground, 75% from left

**Special Properties:**
- No hazards (safe arena)
- Fixed camera (no dynamic follow)
- Neutral dark gray background

## Adding New Stages

### Step 1: Create JSON Configuration

Create `game/resources/stages/my_stage.json`:

```json
{
  "id": "my_stage",
  "name": "My Custom Stage",
  "description": "A new battlefield",
  "boundaries": {
    "left": 50,
    "right": 1230,
    "top": 0,
    "bottom": 650
  },
  "spawn_points": {
    "player_1": { "x": 320, "y": 650 },
    "player_2": { "x": 960, "y": 650 }
  },
  "camera": {
    "enabled": false,
    "limit_left": 0,
    "limit_right": 1280,
    "limit_top": 0,
    "limit_bottom": 720
  },
  "hazards": []
}
```

### Step 2: Create Scene File

Create `game/scenes/stages/my_stage.tscn`:

```gdscript
[gd_scene load_steps=1 format=3 uid="uid://custom_uid"]

[ext_resource type="Script" path="res://scripts/stages/base_stage.gd"]

[node name="MyStage" type="Node2D"]
script = ExtResource("res://scripts/stages/base_stage.gd")
stage_name = "My Custom Stage"
stage_id = "my_stage"

[node name="Background" type="ColorRect" parent="."]
offset_left = 0.0
offset_top = 0.0
offset_right = 1280.0
offset_bottom = 720.0
color = Color(0.3, 0.3, 0.3, 1)
```

### Step 3: Register in StageLoader

Update `game/scripts/stages/stage_loader.gd`:

```gdscript
const STAGES = {
	"arena_1": "res://scenes/stages/arena_1.tscn",
	"my_stage": "res://scenes/stages/my_stage.tscn"  # Add this line
}
```

### Step 4: Load Your Stage

```gdscript
var stage = StageLoader.load_stage("my_stage")
```

## Collision System Details

### How Collisions Work

1. **Ground**: StaticBody2D with RectangleShape2D (20px tall)
   - Characters land here via gravity
   - `is_on_floor()` returns true when standing

2. **Walls**: StaticBody2D at left (X=50) and right (X=1230)
   - Stop character horizontal movement
   - 10px wide collision boxes

3. **Characters**: CharacterBody2D (BaseFighter)
   - Collision layer 1 (matches stage)
   - move_and_slide() handles sliding along surfaces

### Physics Setup

All stages use:
- **Layer 1**: Characters
- **Mask 1**: Characters, ground, walls
- **Gravity**: 800 (defined in BaseFighter)
- **Friction**: Knockback decay at 0.85/frame

## Camera Configuration

### Fixed Camera (MVP)
```json
"camera": {
  "enabled": false,
  "limit_left": 0,
  "limit_right": 1280,
  "limit_top": 0,
  "limit_bottom": 720
}
```

Center camera on stage with no follow behavior.

### Dynamic Camera (Future)
```json
"camera": {
  "enabled": true,
  "limit_left": 0,
  "limit_right": 1280,
  "limit_top": 0,
  "limit_bottom": 720
}
```

When enabled, camera will follow player positions (implementation pending).

## Hazard Support (Future)

Currently, the schema supports hazards but implementation is deferred. Structure:

```json
"hazards": [
  {
    "id": "spike_1",
    "type": "spike",
    "position": { "x": 640, "y": 600 },
    "size": { "width": 50, "height": 50 },
    "damage": 10
  }
]
```

Types: `spike`, `fire`, `moving_platform`, `custom`

## Testing Checklist

- [ ] Stage loads without errors
- [ ] Ground collision works (character lands)
- [ ] Left wall collision works (character stops)
- [ ] Right wall collision works (character stops)
- [ ] Player 1 spawns at correct position
- [ ] Player 2 spawns at correct position
- [ ] Camera is centered on stage
- [ ] Background is visible
- [ ] Stage is in bounds check works
- [ ] `get_stage_center()` returns correct value

## Performance Notes

- All collisions are simple RectangleShape2D (efficient)
- No physics simulation on background
- Stages are lightweight and can be instantiated/destroyed quickly
- JSON loading is cached by Godot ResourceLoader

## Troubleshooting

### Characters fall through ground
- Check that StaticBody2D collision is properly set up
- Verify ground Y position in boundaries
- Ensure characters use move_and_slide()

### Characters can't collide with walls
- Verify wall collision shapes are created
- Check that walls have correct X positions
- Ensure collision layers match between stage and characters

### Stage won't load
- Check that scene file path is correct in StageLoader
- Verify JSON file exists and is valid
- Check browser console for error messages

### Spawn points are wrong
- Verify spawn_points in arena_1.json
- Check that Y coordinate is at ground level (650)
- Ensure X coordinates are within boundaries (50-1230)

## Related Files

- `/game/scripts/stages/base_stage.gd` - Stage base class
- `/game/scripts/stages/stage_loader.gd` - Loading utility
- `/game/scripts/stages/stage_data_loader.gd` - Data parsing utility
- `/game/resources/stages/arena_1.json` - Arena 1 configuration
- `/game/resources/schemas/stage_schema.json` - JSON schema
- `/game/scenes/stages/arena_1.tscn` - Arena 1 scene

## Next Steps

1. Integrate stages into battle scene manager
2. Test collision with actual characters
3. Implement hazard detection system
4. Add camera follow for dynamic stages
5. Create additional stage variants
6. Add stage selection/loading menu
