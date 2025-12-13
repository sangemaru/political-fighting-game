# Combat System Setup Guide

## Overview

This guide walks through setting up the combat system for the Political Fighting Game. All components are in place; this documents the configuration needed in Godot.

## Prerequisites

- ✓ hitbox.gd created
- ✓ hurtbox.gd created
- ✓ damage_calculator.gd created
- ✓ attack_state_machine.gd created
- ✓ base_fighter.gd enhanced with knockback physics
- ✓ fighter_state_machine.gd with frame-based hitstun

## Step 1: Configure Physics Layers in project.godot

Open `project.godot` and add physics layers configuration:

```
[physics]

physics/2d/default_gravity=800.0
physics/2d/default_gravity_vector=Vector2(0, 1)

# Layer Names (for debugging)
physics/2d/layer_names/2d_physics/layer_1="Characters"
physics/2d/layer_names/2d_physics/layer_2="Hitboxes"
physics/2d/layer_names/2d_physics/layer_3="Hurtboxes"
physics/2d/layer_names/2d_physics/layer_4="World"
```

**Layer Breakdown**:
- **Layer 1**: Character bodies (CharacterBody2D)
- **Layer 2**: Hitboxes (Area2D - attacks)
- **Layer 3**: Hurtboxes (Area2D - vulnerable)
- **Layer 4**: World geometry (walls, platforms, etc.)

## Step 2: Create Character Scene with Combat Components

Create a character scene `game/scenes/fighter_template.tscn`:

```
CharacterBody2D (BaseFighter)
├── Sprite2D
├── CollisionShape2D (character body)
├── Hurtbox (Area2D)
│   ├── CollisionShape2D (hurtbox)
│   └── [Script: hurtbox.gd]
├── Hitbox (Area2D) - Created at runtime
│   ├── CollisionShape2D (hitbox)
│   └── [Script: hitbox.gd]
└── FighterStateMachine (inner class)
```

### CharacterBody2D Setup

**Script**: `base_fighter.gd`

**Properties**:
- max_health: 100
- speed: 200.0
- weight: 1.0
- gravity: 800.0
- jump_height: 150.0

**Physics Configuration**:
- Collision Layer: **1** (Characters)
- Collision Mask: **1** (Characters only)
- Gravity Scale: 1.0

---

### Hurtbox (Area2D) Setup

**Script**: `hurtbox.gd`

**Child: CollisionShape2D**
- Shape: CapsuleShape2D (covers torso)
- Radius: ~15 pixels
- Height: ~40 pixels

**Physics Configuration**:
- Collision Layer: **4** (Layer 3 in UI) - Hurtboxes
- Collision Mask: **0** (Passive detection)
- Monitorable: ON (can be detected)
- Monitoring: OFF (doesn't detect anything)

**Signals to Connect** (optional):
```gdscript
# In character scene _ready():
hurtbox.hit_received.connect(_on_hurtbox_hit)

func _on_hurtbox_hit(damage: int, kb_force: int, stun_frames: int):
    # Could play hit effect here
    pass
```

---

### Hitbox (Area2D) Setup - Runtime Creation

Hitbox is created at runtime during attack startup. In character script:

```gdscript
func _create_attack_hitbox(damage: int, kb_force: int, stun: int) -> Hitbox:
    var hitbox = Area2D.new()
    var shape = CapsuleShape2D.new()
    shape.radius = 12
    shape.height = 35

    var collision = CollisionShape2D.new()
    collision.shape = shape
    hitbox.add_child(collision)

    # Setup hitbox script and collision
    var hb_script = load("res://game/scripts/combat/hitbox.gd")
    hitbox.set_script(hb_script)

    # Physics configuration
    hitbox.collision_layer = 0
    hitbox.collision_mask = 4  # Only detect hurtboxes (layer 3)

    add_child(hitbox)
    hitbox.set_hitbox_data(damage, kb_force, stun, self, "attack_01")

    return hitbox
```

---

## Step 3: Attack Integration with State Machine

### Attack State Machine Setup

In character's `_ready()`:

```gdscript
func _ready() -> void:
    health = max_health
    _initialize_state_machine()
    _setup_physics_layer()
    _initialize_attack_system()

func _initialize_attack_system() -> void:
    attack_fsm = AttackStateMachine.new()
    add_child(attack_fsm)
    attack_fsm.change_state(AttackStateMachine.State.IDLE)
```

### Frame-by-Frame Processing

In character's `_process(delta)`:

```gdscript
func _process(delta: float) -> void:
    if state_machine:
        state_machine.process_state(delta)

    # Process attack state machine every frame
    if attack_fsm:
        attack_fsm.process_frame()

    # Handle attack input
    if attack_fsm.can_attack() and Input.is_action_just_pressed("p1_attack"):
        _execute_attack("jab")

func _execute_attack(attack_name: String) -> void:
    # Get attack data from character sheet (frame data)
    var attack_data = {
        "damage": 10,
        "startup": 5,
        "active": 6,
        "recovery": 15,
        "knockback": 200,
        "hitstun": 12
    }

    # Create hitbox
    var hitbox = _create_attack_hitbox(
        attack_data["damage"],
        attack_data["knockback"],
        attack_data["hitstun"]
    )

    # Start attack state machine
    attack_fsm.start_attack(
        attack_data["startup"],
        attack_data["active"],
        attack_data["recovery"],
        hitbox
    )
```

---

## Step 4: Collision Layer Verification

### Scene Tree Example

```
Player1 (CharacterBody2D)
├── collision_layer = 1
├── collision_mask = 1
├── Hurtbox (Area2D)
│   ├── collision_layer = 4 (Hurtboxes)
│   ├── collision_mask = 0
│   └── CollisionShape2D (CapsuleShape2D)
└── Hitbox (Area2D) [created at runtime]
    ├── collision_layer = 0
    ├── collision_mask = 4 (detect Hurtboxes)
    └── CollisionShape2D (CapsuleShape2D)

Player2 (CharacterBody2D)
├── collision_layer = 1
├── collision_mask = 1
└── Hurtbox (Area2D)
    ├── collision_layer = 4
    ├── collision_mask = 0
    └── CollisionShape2D (CapsuleShape2D)
```

### Verify Collision Setup

In Godot Editor:

1. Open Render Debugger
2. Select "Physics 2D"
3. Verify layers light up correctly:
   - **Blue (Layer 1)**: Character bodies
   - **Red (Layer 2)**: Hitboxes (when active)
   - **Green (Layer 3)**: Hurtboxes
   - **Yellow (Layer 4)**: World geometry

---

## Step 5: Damage Calculator Setup

Integrate DamageCalculator for calculating final damage:

```gdscript
# In character class
var damage_calc: DamageCalculator

func _ready() -> void:
    # ... other setup ...
    damage_calc = DamageCalculator.new()

# When attack lands (in hurtbox)
func receive_damage(attacker: BaseFighter, base_damage: int) -> void:
    var final_damage = damage_calc.calculate_damage(
        base_damage,
        attacker.attack_power,  # From character stats
        self.defense,           # From character stats
        damage_calc.combo_count
    )

    take_damage(final_damage)
    damage_calc.add_combo_hit()
```

---

## Step 6: Testing Combat System

### Test 1: Collision Detection

```gdscript
# In _process, add debug output:
if hitbox and hitbox.is_monitoring():
    var overlapping = hitbox.get_overlapping_areas()
    print("Hitbox detecting: ", overlapping.size(), " hurtboxes")
```

**Expected**:
- When Hitbox is active (ACTIVE state), should detect opponent Hurtbox
- Should NOT detect own hurtbox (different owner check)

### Test 2: Damage Application

```gdscript
# When hurtbox is hit:
# Should see in output:
# - Health decreased
# - Knockback applied
# - Hitstun frames set
```

### Test 3: Frame Data

```gdscript
# Print attack state each frame:
print("Attack: ", attack_fsm.get_state_name(),
      " Frame: ", attack_fsm.get_attack_frame())
```

**Expected Output**:
```
Attack: STARTUP Frame: 1
Attack: STARTUP Frame: 2
Attack: STARTUP Frame: 3
Attack: STARTUP Frame: 4
Attack: STARTUP Frame: 5
Attack: ACTIVE Frame: 1
Attack: ACTIVE Frame: 2
... (hit connects here if opponent in range)
Attack: RECOVERY Frame: 1
Attack: RECOVERY Frame: 2
... continues through recovery
Attack: IDLE Frame: 0
```

---

## Troubleshooting

### Hitbox Not Detecting Hurtbox

**Checklist**:
- [ ] Hitbox collision_layer = 0
- [ ] Hitbox collision_mask = 4 (layer 3)
- [ ] Hurtbox collision_layer = 4 (layer 3)
- [ ] Hurtbox collision_mask = 0
- [ ] Both have valid CollisionShape2D children
- [ ] Hitbox.monitoring = true during ACTIVE state
- [ ] Hitboxes overlap in space (use Physics 2D debug)

### Damage Not Applying

**Checklist**:
- [ ] hurtbox.receive_hit() is called
- [ ] owner_fighter reference is set
- [ ] fighter.take_damage() is implemented
- [ ] health signal emitted

### Knockback Not Working

**Checklist**:
- [ ] apply_knockback() is called with valid direction/force
- [ ] knockback_velocity is multiplied by weight
- [ ] physics_process applies knockback to velocity
- [ ] knockback_friction is between 0.8-0.9

### Hitstun Not Blocking Input

**Checklist**:
- [ ] set_hitstun_frames() is called with > 0 frames
- [ ] Fighter state machine is in HITSTUN state
- [ ] Frame counter increments in _process
- [ ] Transition back to IDLE after frames elapsed

---

## Next Steps

1. **Create Character Data Files**: Add JSON files for each character with their move data (damage, frame data, etc.)
2. **Implement Special Attacks**: Extend attack system to handle special move timing
3. **Add Hit Effects**: Play sounds/particles when attacks connect
4. **Implement Guard**: Add blocking/parry mechanics
5. **Network Sync**: Ensure deterministic behavior for rollback netplay
