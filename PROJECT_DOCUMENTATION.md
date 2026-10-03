# Moving Connected — Project Documentation

Comprehensive technical documentation for **Moving Connected**, a 2D grid/arena multi-character puzzle game developed in Godot 4.

---

## 1. Overview & Core Concept

**Moving Connected** is a multi-avatar navigation puzzle game.
- **Simultaneous Input:** All players receive identical movement inputs (`ui_left`, `ui_right`, `ui_up`, `ui_down`) and move in unison at the same speed.
- **Visual Connection:** All players are linked by a `Line2D` polygon that stretches dynamically between them.
- **Scalable Avatars & Exits:** Supports an arbitrary number of players ($N$) and exit points specified via JSON.
- **Level Objective:** Every exit point must be occupied simultaneously by a distinct player (1-to-1 matching) to achieve level completion.
- **Hazards & Puzzles:** Players must negotiate fixed blocks, shifting blocks, signal gates (pressure switches), and danger zones (static, moving, and timed).
- **Camera Cycling:** The player can press `Tab` (`switch_camera`) to cycle the camera view across each avatar.

---

## 2. Controls & Keybindings

| Action | Input Mapping | Description |
|---|---|---|
| `ui_left` | Left Arrow / A / D-pad Left | Moves all players left |
| `ui_right` | Right Arrow / D / D-pad Right | Moves all players right |
| `ui_up` | Up Arrow / W / D-pad Up | Moves all players up |
| `ui_down` | Down Arrow / S / D-pad Down | Moves all players down |
| `switch_camera` | `Tab` (Physical Key 4194306), Joypad Button 9, Joypad Axis | Cycles camera focus to the next player avatar |

---

## 3. Project Directory Map

```
moving-connected/
├── project.godot                     # Engine settings, main scene, input mapping
├── icon.svg                          # Default Godot icon used as player sprite texture
├── PROJECT_DOCUMENTATION.md          # Comprehensive architecture & developer guide (this file)
│
├── levels_data/
│   ├── level.json                    # Active level layout data (bounds, players, exits, obstacles)
│   └── level_data_doc.txt            # Schema explanation and format definitions
│
├── util/
│   └── file_names.gd                 # Global path constants (FileNames class)
│
├── file_io_manager/
│   └── file_io.gd                    # Static utility to load files from disk (FileIO class)
│
├── game_data_manager/
│   ├── level_data_parser.gd          # Parses raw JSON into typed LevelData (LevelDataParser class)
│   └── sub_classes/
│       ├── level_data.gd             # Container DTO for all level properties (LevelData)
│       ├── single_point_position.gd  # Vector2 wrapper with optional direction (SinglePointPosition)
│       ├── two_point_position.gd     # Bounding box coordinates (TwoPointPosition)
│       └── signal_gate_data.gd       # Block and switch vector pairs (SignalGateData)
│
├── game_components/
│   ├── player/
│   │   ├── player.gd                 # CharacterBody2D movement controller
│   │   └── player.tscn               # Reusable player avatar scene
│   │
│   └── obstacles/
│       ├── fixed_block/
│       │   ├── fixed_block.gd        # StaticBody2D static obstacle
│       │   └── fixed_block.tscn
│       ├── shifting_block/
│       │   ├── shifting_block.gd     # StaticBody2D obstacle patrolling on tween
│       │   └── shifting_block.tscn
│       ├── exit_point/
│       │   ├── exit_point.gd         # Area2D goal with occupancy detection & color swap
│       │   └── exit_point.tscn
│       ├── signal_gate/
│       │   ├── signal_gate.gd        # Node2D managing StaticBody2D gate + Area2D switch
│       │   └── signal_gate.tscn
│       └── danger_zone/
│           ├── fixed_danger_zone.gd    # Area2D static hazard (reloads scene on contact)
│           ├── fixed_danger_zone.tscn
│           ├── shifting_danger_zone.gd # Area2D patrolling hazard
│           ├── shifting_danger_zone.tscn
│           ├── timed_danger_zone.gd    # Area2D pulsing on/off hazard
│           └── timed_danger_zone.tscn
│
├── prototype/
│   ├── prototype.tscn                # Main run scene (contains GameLauncher, Line2D, Env)
│   └── line_2d.gd                    # Connects all active player nodes dynamically
│
└── game_launcher/
    └── game_launcher.gd              # Orchestrates scene instantiation, camera, and win/fail rules
```

---

## 4. Level Data Schema (`level.json`)

Levels are authored in standard JSON loaded at runtime:

```json
{
  "w": [[0, 0], [1000, 600]],
  "p": [[800, 400], [800, 500]],
  "e": [[900, 400], [900, 500]],
  "o": {
    "fb": [[100, 50], [300, 100]],
    "sb": [[200, 100, 0], [150, 200, 1]],
    "sg": [[500, 100, 450, 100], [600, 300, 550, 300]],
    "fd": [[200, 500], [400, 300]],
    "sd": [[400, 400, 0], [600, 400, 1]],
    "td": [[600, 200], [600, 100]]
  }
}
```

### Key Reference

| Key | Format | Type | Description |
|---|---|---|---|
| `w` | `[[left, top], [right, bottom]]` | `TwoPointPosition` | Playable arena bounding box. Used to construct border walls and set camera limits. |
| `p` | `[[x1, y1], [x2, y2], ...]` | `Array[SinglePointPosition]` | Initial spawn coordinates for $N$ player avatars. |
| `e` | `[[x1, y1], [x2, y2], ...]` | `Array[SinglePointPosition]` | Coordinates for $N$ exit points. |
| `o.fb` | `[[x, y], ...]` | `Array[SinglePointPosition]` | Fixed blocks (static solid obstacles). |
| `o.sb` | `[[x, y, d], ...]` | `Array[SinglePointPosition]` | Shifting blocks (moving solid obstacles). `d`: `0 = vertical`, `1 = horizontal`. |
| `o.sg` | `[[bx, by, sx, sy], ...]` | `Array[SignalGateData]` | Signal gates. `bx, by` = Gate block position; `sx, sy` = Switch trigger position. |
| `o.fd` | `[[x, y], ...]` | `Array[SinglePointPosition]` | Fixed danger zones (static lethal areas). |
| `o.sd` | `[[x, y, d], ...]` | `Array[SinglePointPosition]` | Shifting danger zones (moving lethal areas). `d`: `0 = vertical`, `1 = horizontal`. |
| `o.td` | `[[x, y], ...]` | `Array[SinglePointPosition]` | Timed danger zones (pulsing lethal areas). |

> **Note on Directions:** In both `sb` (shifting blocks) and `sd` (shifting danger zones), `d = 0` indicates vertical motion, and `d = 1` indicates horizontal motion.

---

## 5. Architectural Components & Mechanics

### 5.1 Game Launcher (`game_launcher/game_launcher.gd`)
Attached to the root node of `prototype.tscn`. Performs level initialization and game-loop monitoring:
1. **Reads JSON:** Loads file via `FileIO.readFile(FileNames.Level)` and parses via `LevelDataParser.parseLevelData(...)`.
2. **Walls Construction (`_setupWalls`):**
   - Generates four perimeter boundaries (Top, Bottom, Left, Right) as `Sprite2D` + `CollisionShape2D` added to `$Env/Walls`.
   - Centers each wall taking bounding origin offsets into account (`left + (right - left) / 2`, etc.).
3. **Player Spawning (`_setupPlayers`):**
   - Instantiates `PlayerScene` for every point in `levelData.playersLocations`.
   - Stores avatars in `_players: Array[Node2D]`. *(Invariant typing requirement: `Array[Node2D]` is required to pass to `Line2D.set_tracked_nodes`)*.
4. **Camera Setup (`_setupCamera`):**
   - Dynamically creates a `Camera2D` with physics process callback and position smoothing enabled.
   - Constrains camera movement to the arena boundaries (`limit_left`, `limit_top`, `limit_right`, `limit_bottom`).
   - Attaches the camera as a child of the first player (`_players[0]`).
5. **Camera Cycling (`_cycle_camera`):**
   - Listens to `_unhandled_input` for `switch_camera` (mapped to `Tab`).
   - Reparents the camera to `_players[_current_camera_index]` and resets local position to `Vector2.ZERO`.
6. **Connecting Line (`_setupLine`):**
   - Passes `_players` to `$Line2D`.
7. **Win Condition (`_check_win_condition`):**
   - Iterates through all instantiated exit points.
   - Collects unique player occupants across all exits (`get_occupants()`).
   - If each exit has an occupant and `occupied_by.size() >= _exit_points.size()`, triggers `_on_level_complete()`.
8. **Loss Condition (`_on_player_hit_danger`):**
   - Triggered when any avatar enters a danger zone.
   - Prints failure log and calls `get_tree().reload_current_scene()`.

### 5.2 Player (`game_components/player/`)
- Root is a `CharacterBody2D` with `RectangleShape2D` (32×32) and scaled `Sprite2D`.
- Velocity is calculated from `Input.get_axis("ui_left", "ui_right")` and `Input.get_axis("ui_up", "ui_down")` normalized and multiplied by `SPEED = 300.0`.
- Moves using `move_and_slide()` (delta is handled internally by Godot).

### 5.3 Connecting Line (`prototype/line_2d.gd`)
- Tracks dynamic array of `Node2D` nodes passed to `set_tracked_nodes(...)`.
- Clears points and allocates one vertex per player.
- During `_process`, updates local point coordinates using `to_local(node.global_position)`.
- With `closed = true` on the `Line2D` scene, renders a closed polygon connecting all avatars.

### 5.4 Exit Points (`game_components/obstacles/exit_point/`)
- `Area2D` with 50×50 dimension.
- Maintains `_occupants: Array[Node2D]` updated via `body_entered` and `body_exited`.
- **Visual Feedback:**
  - Unoccupied: Semi-transparent green `Color(0.0, 1.0, 0.2, 0.8)`.
  - Occupied: Solid yellow `Color(1.0, 0.9, 0.0, 1.0)`.

### 5.5 Signal Gates (`game_components/obstacles/signal_gate/`)
- Root is `Node2D` which dynamically instantiates two sub-elements:
  1. **Gate Block (`StaticBody2D`):** Located at `block_position`. Size 20×50.
     - Closed: Solid purple `Color(0.5, 0.0, 1.0, 1.0)`, collision active.
     - Open: Translucent purple `Color(0.5, 0.0, 1.0, 0.25)`, collision shape disabled via `set_deferred("disabled", true)`.
  2. **Switch (`Area2D`):** Located at `switch_position`. Size 20×20.
     - Green texture `Color(0.0, 0.8, 0.4, 0.8)`.
     - Detects player entry/exit. When 1 or more players stand on the switch, the gate opens; when vacated, it closes.

### 5.6 Danger Zones (`game_components/obstacles/danger_zone/`)
- Red hazards (`Color(1.0, 0.0, 0.0, 0.7)`).
- **Fixed Danger Zone:** Static `Area2D`.
- **Shifting Danger Zone:** `Area2D` patrolling `movementDistance = 100.0` px back-and-forth along the configured axis using looping tweens.
- **Timed Danger Zone:** `Area2D` alternating between active (monitored, solid red) and inactive (unmonitored, 15% opacity red) every 2.0 seconds via coroutine.

---

## 6. Developer Guidelines for Future Extensions

### Adding New Levels / Multi-Level Loading
1. Create new JSON files in `res://levels_data/` (e.g. `level_01.json`, `level_02.json`).
2. Add corresponding path constants to `util/file_names.gd`.
3. In `game_launcher.gd`, replace hardcoded `FileNames.Level` with a level manager variable or argument (e.g. `current_level_path`).
4. On `_on_level_complete()`, load the next level file or transit to a victory screen.

### Creating New Obstacle Types
1. **Scene & Script:** Place under `res://game_components/obstacles/<new_type>/`.
2. **Resource Path:** Register in `util/file_names.gd` under `FileNames`.
3. **Data Model:** Update `LevelData` (`game_data_manager/sub_classes/level_data.gd`) with a typed array.
4. **Parser:** Add parser extraction in `game_data_manager/level_data_parser.gd`.
5. **Launcher:** Add instantiation loop in `game_launcher.gd`.

### GDScript Type Invariance Notice
In GDScript, typed arrays are invariant:
- `Array[CharacterBody2D]` **cannot** be passed to a function expecting `Array[Node2D]`, even though `CharacterBody2D` inherits from `Node2D`.
- Always store polymorphic node lists as `Array[Node2D]` if they are shared across modules (e.g. `_players` in `game_launcher.gd`).
