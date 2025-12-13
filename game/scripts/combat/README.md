# Combat System Documentation

## Overview

The combat system implements frame-perfect, deterministic fighting game mechanics. All timing is based on frames (60 FPS) for consistent replay and netplay support.

## Core Components

### 1. Hitbox System (`hitbox.gd`)

**Purpose**: Attack collision areas that deal damage to opponents.

**Key Features**:
- Frame-perfect activation during attack window (ACTIVE frames)
- Prevents same attack hitting multiple times on same target
- Tracks damage, knockback, and hitstun values
- Automatically deactivates after attack ends

**Properties**:
- `damage`: Base damage dealt (integer)
- `knockback_force`: Force applied to opponent (integer)
- `hitstun_frames`: Frames opponent is stunned (integer)
- `owner_fighter`: Reference to attacking character
- `attack_id`: Unique identifier per attack instance

**Usage**:
```gdscript
# Create hitbox in attack startup
var hitbox = Hitbox.new()
add_child(hitbox)
hitbox.set_hitbox_data(10, 200, 12, self, "punch_01")

# Activate during ACTIVE frames
hitbox.activate()

# Deactivate after attack ends
hitbox.deactivate()
```

---

### 2. Hurtbox System (`hurtbox.gd`)

**Purpose**: Vulnerable collision areas that receive damage.

**Key Features**:
- Detects incoming hitboxes
- Passes hit data to character for processing
- Emits signal for external systems (sound, particles)

**Properties**:
- `owner_fighter`: Reference to vulnerable character

**Usage**:
```gdscript
# Create hurtbox in character body
var hurtbox = Hurtbox.new()
add_child(hurtbox)
hurtbox.set_owner(self)
```

---

### 3. Damage Calculator (`damage_calculator.gd`)

**Purpose**: Calculates final damage with stats and combo scaling.

**Formula**:
```
damage = base_damage * (attacker_power / defender_defense) * combo_scaling
combo_scaling = 0.9^(hit_number)  # 10% reduction per hit
```

**Key Features**:
- Stats-based damage calculation
- Combo damage scaling (prevents unlimited damage chains)
- Tracks combo counter

**Combo Scaling Examples**:
- 1st hit: 100% damage
- 2nd hit: 90% damage
- 3rd hit: 81% damage
- 4th hit: 72.9% damage

**Usage**:
```gdscript
var calc = DamageCalculator.new()

# Calculate first hit
var dmg = calc.calculate_damage(10, 8, 4, 0)  # Returns 20

# Add combo hit and recalculate
calc.add_combo_hit()
dmg = calc.calculate_damage(10, 8, 4, 1)  # Returns 18 (10% reduction)
```

---

### 4. Attack State Machine (`attack_state_machine.gd`)

**Purpose**: Manages attack phases with frame-perfect timing.

**States**:
1. **IDLE** - Not attacking, can receive new attack input
2. **STARTUP** - Before hitbox active (vulnerable period)
3. **ACTIVE** - Hitbox is active (can hit opponent)
4. **RECOVERY** - After hitbox deactivated (vulnerable period)

**Frame Data**:
- `startup_frames`: Frames before attack connects (2-15 typical)
- `active_frames`: Frames hitbox is active (1-8 typical)
- `recovery_frames`: Frames after attack (5-25 typical)

**Collision Layer Setup**:
```
Layer 1 (Characters): CharacterBody2D nodes
Layer 2 (Hitboxes):   Area2D hitboxes
Layer 3 (Hurtboxes):  Area2D hurtboxes
```

**Usage**:
```gdscript
var attack_fsm = AttackStateMachine.new()
add_child(attack_fsm)

# When attack input pressed
if attack_fsm.can_attack():
    attack_fsm.start_attack(5, 6, 15, hitbox)
    # 5 startup, 6 active, 15 recovery frames
```

---

### 5. Knockback Physics

**Implementation** (`base_fighter.gd`):

Knockback is applied as velocity per frame, with friction decay:

```gdscript
knockback_velocity = direction.normalized() * force * (1.0 / weight)
knockback_velocity *= 0.85  # Decay 15% per frame
```

**Key Features**:
- Weight affects knockback resistance (heavier = less knockback)
- Exponential decay (0.85 = ~15% per frame)
- Applies even when character is in hitstun
- Can push character into walls/boundaries

**Knockback Formula**:
```
initial_knockback = force / weight
final_velocity = knockback_velocity * 0.85^frames_elapsed
```

---

### 6. Hitstun System

**Implementation** (`fighter_state_machine.gd` - `_HitstunState`):

Frame-based stun duration when hit.

**Key Features**:
- Prevents input during hitstun
- Scales with damage dealt (typically 1 frame per 5 damage)
- Character can still be knocked around (combo-able)
- Recovery animation after hitstun ends

**Usage** (in hurtbox):
```gdscript
var hitstun_frames = 12  # Stun for 12 frames (0.2 seconds)
owner_fighter.state_machine.set_hitstun_frames(hitstun_frames)
```

---

## Collision Layers (Critical Setup)

**PhysicsBody2D** (Characters):
- Collision Layer: 1
- Collision Mask: 1

**Area2D** (Hitboxes):
- Collision Layer: 2
- Collision Mask: 4 (detect hurtboxes on layer 3)

**Area2D** (Hurtboxes):
- Collision Layer: 4
- Collision Mask: 0 (passive, detected by hitboxes)

---

## Frame Data Format (JSON Reference)

From `character_schema.json`:

```json
{
  "name": "Character Name",
  "moves": [
    {
      "name": "Jab",
      "input": "attack",
      "damage": 10,
      "startup": 5,
      "active": 6,
      "recovery": 15,
      "hitbox": {
        "offset_x": 20,
        "offset_y": 0,
        "width": 40,
        "height": 30
      }
    }
  ]
}
```

**Frame Data Interpretation**:
- **startup**: Frames before hit connects (make attack vulnerable enough)
- **active**: Frames hitbox can connect (usually 1-8 frames)
- **recovery**: Frames after attack (opening for opponent)
- **total_duration**: startup + active + recovery

**Example Startup Analysis** (5 frame startup = 1/12 second):
- At 60 FPS, 5 frames = ~83ms to connect
- Player presses button, 5 frames to see animation
- Good for arcade-style instant response
- Easy to confirm combos

---

## Integration Flow

```
1. Character Input → Attack Request
2. Attack State Machine → Check if can attack (IDLE state)
3. Create/Activate Hitbox → Set damage/knockback/hitstun
4. Process Frames:
   - STARTUP: Character vulnerable, hitbox inactive
   - ACTIVE: Hitbox active, can connect
   - RECOVERY: Hitbox inactive, character vulnerable
5. Hitbox-Hurtbox Collision:
   - Hitbox.area_entered(hurtbox)
   - Check if target already hit this attack
   - Calculate damage → DamageCalculator
   - Apply damage → BaseFighter.take_damage()
   - Apply knockback → BaseFighter.apply_knockback()
   - Set hitstun → FighterStateMachine.set_hitstun_frames()
6. Character enters HITSTUN state
7. After hitstun duration → Return to IDLE/WALKING/JUMPING
```

---

## Example: Complete Attack Sequence

```gdscript
# In character input handler
if Input.is_action_just_pressed("p1_attack"):
    if attack_fsm.can_attack():
        # Punch frame data: 5 startup, 6 active, 15 recovery
        attack_fsm.start_attack(5, 6, 15, hitbox)

# In _process each frame
attack_fsm.process_frame()

# Frame 0-4: STARTUP state
#   - Character plays startup animation
#   - Hitbox exists but is deactivated
#   - Character can be hit (vulnerable)

# Frame 5-10: ACTIVE state
#   - Hitbox is activated (can connect)
#   - If hits opponent: emit signal, apply damage
#   - Character still vulnerable during active frames

# Frame 11-25: RECOVERY state
#   - Hitbox deactivated
#   - Character plays recovery animation
#   - Character vulnerable (opening for opponent)
#   - Cannot be hit but input locked

# Frame 26+: IDLE state
#   - Attack complete
#   - Character can move/attack again
```

---

## Testing Checklist

- [ ] Collision layers properly configured (1, 2, 4)
- [ ] Hitbox activates/deactivates at correct frames
- [ ] Damage calculated with combo scaling
- [ ] Knockback applies and decays correctly
- [ ] Hitstun prevents input
- [ ] Attack state transitions work frame-perfect
- [ ] Hurtbox detects all hitbox types
- [ ] No duplicate hits on single attack
- [ ] Weight affects knockback properly
- [ ] Frame data matches animation timings

---

## Performance Notes

- All timing is frame-based (no delta-time calculations)
- Hitbox detection only occurs when hitbox is active
- Combo scaling prevents damage runaway
- Knockback decay is exponential (fast early, slow later)
