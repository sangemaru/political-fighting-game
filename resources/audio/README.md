# Audio Assets

## Status: Placeholder (System Wired, Audio Silent)

The audio system is fully implemented and integrated, but **no audio files are currently included**. The system will fail silently when audio files are missing.

## Required Audio Files

### Sound Effects (SFX)

Place `.wav` files in `resources/audio/sfx/`:

- `light_hit.wav` - Light punch/kick hit
- `heavy_hit.wav` - Heavy punch/kick hit
- `block.wav` - Blocking a hit
- `whiff.wav` - Missing an attack
- `menu_select.wav` - Menu option selected
- `menu_confirm.wav` - Menu option confirmed
- `menu_back.wav` - Menu back button
- `menu_hover.wav` - Menu hover sound

**Format**: `.wav` (preferred for low latency SFX)

### Music Tracks

Place `.ogg` files in `resources/audio/music/`:

- `menu_theme.ogg` - Main menu background music
- `battle_theme.ogg` - Battle scene background music
- `victory_theme.ogg` - Victory screen music

**Format**: `.ogg` (preferred for music, smaller file size)

## Temporary Solutions

### Option 1: Generate Simple Tones (Bfxr/ChipTone)
Use free tools like [Bfxr](https://www.bfxr.net/) or [ChipTone](https://sfbgames.itch.io/chiptone) to create placeholder 8-bit sounds.

### Option 2: Use Royalty-Free Libraries
- [Freesound.org](https://freesound.org/) - CC0/CC-BY sounds
- [OpenGameArt.org](https://opengameart.org/) - Game-specific assets
- [Incompetech](https://incompetech.com/) - Royalty-free music (attribution)

### Option 3: Procedural Audio (Advanced)
Godot supports `AudioStreamGenerator` for runtime procedural sound generation.

## Integration Points (Already Wired)

The following systems call `AudioManager` methods:

1. **Combat System** (`game/scripts/combat/hitbox.gd`):
   - `AudioManager.play_sfx("light_hit")` on hit
   - `AudioManager.play_sfx("heavy_hit")` on heavy hit
   - `AudioManager.play_sfx("block")` on block
   - `AudioManager.play_sfx("whiff")` on miss

2. **Menu System** (all menu scripts):
   - `AudioManager.play_sfx("menu_hover")` on button hover
   - `AudioManager.play_sfx("menu_select")` on button focus
   - `AudioManager.play_sfx("menu_confirm")` on button press
   - `AudioManager.play_sfx("menu_back")` on back action

3. **Music System**:
   - `AudioManager.play_music("menu_theme")` in main menu
   - `AudioManager.play_music("battle_theme")` in battle scene
   - `AudioManager.play_music("victory_theme")` in victory screen

4. **Options Menu** (`game/scenes/menus/options_menu.tscn`):
   - SFX volume slider
   - Music volume slider

## Testing Without Audio

The game is fully playable without audio files. All audio calls fail silently and do not affect gameplay.

To test the audio system:
1. Add at least one file (e.g., `light_hit.wav`)
2. Trigger the corresponding action (e.g., land a punch)
3. Verify sound plays correctly
