# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-08

### Added

- Core game infrastructure: GameManager, SceneManager, AudioManager, SettingsManager autoloads
- Input system with support for keyboard and gamepad (2 players)
- Game state machine with menu, battle, and pause states
- Combat system with hitbox/hurtbox detection, damage calculation, knockback, and hitstun
- Attack state machine for managing move execution and recovery
- Combo counter with decay timing
- 2 playable characters: Generalissimo (dictator_1) and Demagogue (demagogue_1)
- Character data loaded from JSON resource files
- Fighter state machine with idle, walk, jump, attack, hit, and block states
- Base stage system with data-driven stage loading
- Arena stage (arena_1) as the first playable stage
- Battle scene with player spawning, input routing, and win condition detection
- Round and match flow with configurable rounds-to-win
- Full menu system: Main Menu, Character Select, Stage Select, Options, Controls, Pause, Victory Screen
- Health bars, player HUD, round timer, and battle HUD manager
- Round end overlay and match end screen
- Screen shake and hit effect particles for game feel
- Blocking mechanic for damage mitigation
- Audio system with SFX and music playback, volume controls
- Settings persistence (audio, controls) via SettingsManager
- Controller support with configurable deadzone
- Key rebinding in the Controls menu
- HTML5/WebGL web export with GitHub Actions CI/CD
- GitHub Pages and itch.io deployment pipeline
- Version numbering system (this release)
- Desktop builds: Windows, Linux, macOS export presets and CI
- Changelog (this file)
- GitHub issue templates for bug reports and feature requests
