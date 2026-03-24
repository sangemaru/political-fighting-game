# Network Architecture Design (F90)

## Overview

This document describes the network architecture for the Political Fighting Game.
The design follows a GGPO-style rollback netcode model optimized for 2-player
fighting game sessions over WebRTC.

## Architecture Diagram

```
+------------------+          WebRTC DataChannel          +------------------+
|    Player A      |<--------- Input Exchange ----------->|    Player B      |
|                  |                                      |                  |
|  +-----------+   |   Frame N: Send local input          |   +-----------+  |
|  | Input     |---+-- Receive remote input (or predict) -+---| Input     |  |
|  | Buffer    |   |                                      |   | Buffer    |  |
|  +-----------+   |                                      |   +-----------+  |
|       |          |                                      |        |         |
|  +-----------+   |                                      |   +-----------+  |
|  | Rollback  |   |   On misprediction:                  |   | Rollback  |  |
|  | Manager   |   |   1. Restore state at frame X        |   | Manager   |  |
|  |           |   |   2. Replay frames X..N with          |   |           |  |
|  | Snapshots |   |      corrected inputs                |   | Snapshots |  |
|  | [N frames]|   |   3. Resume at frame N               |   | [N frames]|  |
|  +-----------+   |                                      |   +-----------+  |
|       |          |                                      |        |         |
|  +-----------+   |                                      |   +-----------+  |
|  | Game      |   |   Both sides simulate identically    |   | Game      |  |
|  | State     |   |   (deterministic physics at 60 FPS)  |   | State     |  |
|  +-----------+   |                                      |   +-----------+  |
+------------------+                                      +------------------+

         LAN: Peer-to-peer (direct connection)
         WAN: Relay server (TURN/signaling)
         Web: WebRTC DataChannel (browser-compatible)
```

## Rollback Netcode Strategy

### Why Rollback?

Fighting games require frame-precise input responsiveness. Delay-based netcode
adds visible input lag that degrades the experience. Rollback netcode hides
latency by predicting remote inputs and correcting mispredictions retroactively.

### How It Works

1. **Local Input**: Each frame, the local player's input is captured and sent
   to the remote peer.

2. **Input Prediction**: If remote input hasn't arrived for the current frame,
   the system predicts it (default: repeat last known input).

3. **Simulation**: The game advances using local + predicted remote inputs.

4. **Correction**: When the actual remote input arrives and differs from the
   prediction, the system:
   - Restores the game state to the frame where the misprediction occurred
   - Replays all frames from that point using corrected inputs
   - Resumes normal play at the current frame

5. **Snapshot Ring Buffer**: The last N frames of game state are stored in a
   circular buffer (default: 8 frames / ~133ms at 60 FPS). This limits how
   far back rollbacks can go and bounds memory usage.

### Frame Budget

- **Target**: 60 FPS (16.67ms per frame)
- **Rollback window**: 8 frames max (~133ms)
- **Typical rollback**: 1-3 frames for connections under 100ms RTT
- **Input delay**: 1-2 frames added to reduce rollback frequency

## State Serialization Plan

### Serialized Game State

Every frame, the following state must be capturable and restorable:

```
GameState:
  frame_number: int
  round_timer_frames: int
  current_round: int
  fighters[]:
    player_id: int
    position: Vector2 (x, y)
    velocity: Vector2 (x, y)
    health: int
    max_health: int
    is_alive: bool
    facing_direction: int
    is_blocking: bool
    state_machine_state: int (FighterStateMachine.State enum)
    knockback_velocity: Vector2
    hitstun_frames: int
    hitstun_frame_counter: int
```

### Serialization Format

State is serialized to a flat Dictionary for fast copy/restore. No JSON parsing
at runtime -- Dictionary assignment is used for snapshot operations.

### Determinism Requirements

- **NO randf()** in gameplay code (already enforced project-wide)
- Fixed-point or integer math for physics where possible
- Frame-based timers instead of delta-time for gameplay logic
- Input processed in deterministic order (P1 then P2)
- Physics at fixed 60 ticks/second (already configured in project.godot)

## Input Delay Model

### Input Delay Buffer

A small input delay (1-2 frames) is introduced to give remote inputs time
to arrive before they're needed, reducing rollback frequency.

```
Frame Timeline (2-frame delay):

  Frame 0: Capture input for frame 2
  Frame 1: Capture input for frame 3
  Frame 2: Execute with input from frame 0 (arrived by now)
  ...
```

### Adaptive Delay

The input delay can be adjusted based on measured RTT:
- RTT < 50ms: 1 frame delay
- RTT 50-100ms: 2 frame delay
- RTT 100-150ms: 3 frame delay
- RTT > 150ms: 3 frame delay + visual indicators

## WebRTC Approach (Web Compatibility)

### Why WebRTC?

- Works in web browsers (primary platform)
- Supports peer-to-peer with NAT traversal (ICE/STUN/TURN)
- Low-latency unreliable DataChannels (UDP-like)
- Godot has built-in WebRTC support

### Connection Flow

```
1. Player A creates offer via signaling server
2. Player B receives offer, creates answer
3. ICE candidates exchanged (NAT traversal)
4. DataChannel established (unreliable mode for inputs)
5. Game synchronization begins (frame sync handshake)
6. Match starts
```

### Signaling Server

A lightweight signaling server is needed for the initial WebRTC handshake.
Options:
- Simple WebSocket relay (Node.js or Godot server)
- Firebase Realtime Database (serverless option)
- Custom matchmaking server (future)

## Network Topology

### LAN (Peer-to-Peer Direct)

- Players on the same network connect directly
- No signaling server needed (broadcast/mDNS discovery)
- Lowest possible latency
- Uses Godot's ENet multiplayer for LAN

### WAN (Peer-to-Peer with Relay)

- WebRTC with STUN for NAT traversal
- TURN relay as fallback when direct connection fails
- Signaling server for initial handshake

### Hosted Relay (Future)

- Dedicated relay server for matchmaking
- Consistent connection quality
- Anti-cheat enforcement point

## Implementation Phases

### Phase 1: Foundation (Current - F91/F92)
- Serializable game state (capture/restore)
- Deterministic frame system
- Rollback manager with ring buffer
- Network input wrapper with delay buffer
- No actual networking -- local testing with simulated delay

### Phase 2: Local Network
- WebRTC DataChannel integration
- LAN peer discovery
- Input exchange protocol
- Basic lobby system

### Phase 3: Online Play
- Signaling server deployment
- STUN/TURN integration
- Matchmaking queue
- Connection quality monitoring

## References

- GGPO (Good Game Peace Out): https://www.ggpo.net/
- Godot WebRTC: https://docs.godotengine.org/en/stable/tutorials/networking/webrtc.html
- "Rollback Networking in New Retro Arcade" - GDC Talk
- "Fighting Game Networking" - Infil's Guide
