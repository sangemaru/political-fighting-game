# Demagogue Character Animations (F30)

## Animation Specifications

The Demagogue character uses the following animations with a distinctive bright green color scheme (RGB: 0.2, 0.8, 0.4).

### Idle Animation
- **Name**: `idle`
- **Frame Count**: 4 frames (60 FPS)
- **Duration**: 0.067 seconds per frame
- **Description**: Character stands in relaxed position, slight breathing motion
- **Loop**: Yes

### Walk Animation
- **Name**: `walk`
- **Frame Count**: 6 frames (60 FPS)
- **Duration**: 0.1 seconds per frame (0.6 seconds total)
- **Description**: Character walks forward with dramatic arm movements
- **Loop**: Yes

### Jump Animation
- **Name**: `jump`
- **Frame Count**: 8 frames (60 FPS)
- **Duration**: 0.067 seconds per frame
- **Description**: Character leaps into the air
- **Loop**: No

### Light Attack - Finger Point
- **Name**: `light_attack`
- **Total Frames**: 8 (2 startup + 2 active + 4 recovery)
- **Duration**: 0.133 seconds per frame
- **Description**: Quick pointing gesture with one finger extended
- **Hitbox Active**: Frames 2-3 (active_frames)
- **Loop**: No

### Heavy Attack - Podium Slam
- **Name**: `heavy_attack`
- **Total Frames**: 20 (6 startup + 4 active + 10 recovery)
- **Duration**: 0.1 seconds per frame (2 seconds total)
- **Description**: Dramatic slam motion, rising up and slamming down on podium
- **Hitbox Active**: Frames 6-9 (active_frames)
- **Loop**: No

### Special Attack - Rally Cry
- **Name**: `special`
- **Total Frames**: 21 (5 startup + 8 active + 8 recovery)
- **Duration**: 0.067 seconds per frame (1.4 seconds total)
- **Description**: Character raises arms, mouth open wide in speech, aura effect around body
- **Hitbox Active**: Frames 5-12 (active_frames)
- **Visual Effect**: Slight screen shake, color flash
- **Loop**: No

### Hit Stun Animation
- **Name**: `hitstun`
- **Frame Count**: 4 frames
- **Duration**: 0.1 seconds per frame
- **Description**: Character flinches and recoils from impact
- **Loop**: No

### Knockdown Animation
- **Name**: `knockdown`
- **Frame Count**: 12 frames
- **Duration**: 0.1 seconds per frame (1.2 seconds)
- **Description**: Character falls to the ground and lies prone
- **Recovery**: Transitions to `idle` when health restored above 0
- **Loop**: No

## Animation Implementation Notes

### Color Scheme
- **Sprite Color**: Green (RGB: 0.2, 0.8, 0.4) - Contrasts with Generalissimo's red/brown
- **Secondary Color**: Lighter green highlight for accents
- **Aura Effect**: Faint green glow during special attack

### Frame Timing Reference
At 60 FPS:
- 1 frame = 0.01667 seconds
- 2 frames = 0.033 seconds
- 4 frames = 0.067 seconds
- 6 frames = 0.1 seconds

### Attack Frame Windows (Frame-Perfect)
| Move | Startup | Active | Recovery | Total |
|------|---------|--------|----------|-------|
| Light (Finger Point) | 2 | 2 | 4 | 8 |
| Heavy (Podium Slam) | 6 | 4 | 10 | 20 |
| Special (Rally Cry) | 5 | 8 | 8 | 21 |

### Implementation Steps
1. Create sprite sheets or use procedural rectangles for each animation
2. Add AnimationPlayer to Demagogue1 scene
3. Create animation resources for each state
4. Configure frame timing and looping per specifications
5. Add transition logic between animations in demagogue_1.gd
6. Test hitbox timing during active frames
7. Verify visual contrast between Demagogue and Generalissimo

### Sprite Placeholder Details
- **Size**: 60x80 pixels (scaled 1.5x width, 2x height in scene = 90x160 visual)
- **Anchor**: Center of body
- **Color**: RGB(0.2, 0.8, 0.4) - Bright green (#33CC66)
- **Outline**: Optional black border for visibility

## Animation Controller Integration

Connect animations to the CombatSystem:
```gdscript
func play_move_animation(move_id: String) -> void:
    var move = get_move(move_id)
    if move.is_empty():
        return

    $AnimationPlayer.play(move_id)

    # Disable input during startup
    await get_tree().create_timer(move.get("startup_frames") / 60.0).timeout
```

## Reference: Generalissimo Contrast
- **Generalissimo Color**: Red/Brown (slower, tank archetype)
- **Demagogue Color**: Green (faster, glass cannon archetype)
- **Generalissimo Weight**: 1.2 (heavy)
- **Demagogue Weight**: 0.8 (light)
