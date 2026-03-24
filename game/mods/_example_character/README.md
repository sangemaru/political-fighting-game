# Example Character Mod: The Lobbyist

This is a template mod demonstrating how to add a custom character to the Political Fighting Game.

## Directory Structure

```
_example_character/
  mod_manifest.json   -- Required: mod metadata and file references
  character.json      -- Character data (stats, moves, hitboxes)
  README.md           -- This file (optional, for documentation)
```

## How It Works

1. The game's ModLoader scans `game/mods/` for subdirectories containing a `mod_manifest.json`.
2. The manifest declares the mod type (`character`), version info, and which files to load.
3. For character mods, the `files.data` field points to a JSON file following the character schema.
4. The character appears in the character select screen alongside base game characters.

## Creating Your Own Character Mod

1. Copy this directory and rename it (e.g., `my_character/`).
2. Edit `mod_manifest.json`:
   - Set a unique `mod_id` (lowercase, underscores only).
   - Update `name`, `author`, `description`.
   - Keep `type` as `"character"`.
   - Ensure `game_version` matches or is below the game's current version.
3. Edit `character.json`:
   - Set a unique `id` for the character.
   - Define `base_stats`: health, speed, weight, attack_power, defense.
   - Define `moves` array with at least one move.
   - Each move needs: id, name, input, damage, frame data, knockback, and hitbox.
4. Place your mod folder in `game/mods/` and launch the game.

## Character Data Reference

See `game/resources/schemas/character_schema.json` for the full data specification.

### Base Stats

| Stat | Type | Range | Description |
|------|------|-------|-------------|
| health | int | 1+ | Maximum hit points |
| speed | float | 0.1+ | Movement speed |
| weight | float | 0.5-2.0 | Knockback resistance (higher = heavier) |
| attack_power | float | 0.5+ | Damage multiplier |
| defense | float | 0.5+ | Damage reduction multiplier |

### Move Fields

| Field | Type | Description |
|-------|------|-------------|
| id | string | Unique move identifier |
| name | string | Display name |
| input | string | Input command (e.g., "DOWN + ATTACK") |
| damage | int | Base damage (0+) |
| startup_frames | int | Frames before hitbox activates (1+) |
| active_frames | int | Frames the hitbox is active (1+) |
| recovery_frames | int | Frames of vulnerability after move (1+) |
| knockback | float | Force applied to opponent (0+) |
| hitbox | object | Collision box: offset_x, offset_y, width, height |
