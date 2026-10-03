# Moving Connected — Project Documentation

Comprehensive technical documentation for **Moving Connected**, a 2D multi-avatar navigation puzzle game developed in Godot 4.

---

## 1. Overview & Core Concept

**Moving Connected** is a multi-avatar navigation puzzle game.
- **Simultaneous Input:** All players receive identical movement inputs (`ui_left`, `ui_right`, `ui_up`, `ui_down`) and move in unison at the same speed.
- **Visual Connection:** All players are linked by a `Line2D` polygon that stretches dynamically between them.
- **Scalable Avatars & Exits:** Supports an arbitrary number of players ($N$) and exit points specified via JSON.
- **Level Objective:** Every exit point must be occupied simultaneously by a distinct player (1-to-1 matching) to achieve level completion.
- **Hazards & Puzzles:** Players must negotiate fixed blocks, shifting blocks, signal gates (pressure switches), and danger zones (static, moving, and timed).
- **Camera Cycling:** The player can press `Tab` (`switch_camera`) to cycle the camera view across each avatar.
- **Multi-Level Architecture:** Hierarchical level structure grouped by world (e.g. World 1, World 2), driven by a global `GameManager` singleton.
- **Game Flow Modals:** In-game popup dialogs for **Game Over** (retry, levels, home) and **Level Complete** (next level, retry, levels, home).

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
├── project.godot                     # Engine settings, main scene, autoloads, input mapping
├── icon.svg                          # Default Godot icon used as player sprite texture
├── PROJECT_DOCUMENTATION.md          # Technical documentation & architecture guide
│
├── game_manager/
│   └── game_manager.gd               # Autoload singleton managing worlds, levels, and scene flows
│
├── screens/
│   ├── main_menu/
│   │   ├── main_menu.gd              # Homepage logic: Play (-> Level Select) & Exit
│   │   └── main_menu.tscn            # Homepage UI scene
│   │
│   └── level_select/
│       ├── level_select.gd           # Level selection screen logic
│       └── level_select.tscn         # World 1 & 2 level selection tiles
│
├── levels_data/
│   ├── level.json                    # Default / fallback level layout
│   ├── level_data_doc.txt            # Schema explanation and format definitions
│   ├── world_1/
│   │   ├── level_1_1.json            # World 1, Level 1 (2 players, basic obstacles)
│   │   └── level_1_2.json            # World 1, Level 2 (2 players, signal gate + timed hazard)
│   └── world_2/
│       ├── level_2_1.json            # World 2, Level 1 (3 players, moving & timed hazards)
│       └── level_2_2.json            # World 2, Level 2 (3 players, cross-activating signal gates)
│
├── util/
│   └── file_names.gd                 # Global path constants (FileNames class)
│
├── file_io_manager/
│   └── file_io.gd                    # Static file loader utility (FileIO class)
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
│   ├── ui/
│   │   ├── game_dialogs.gd           # Modal overlay script (Game Over & Level Complete)
│   │   └── game_dialogs.tscn         # CanvasLayer UI overlay
│   │
│   └── obstacles/
│       ├── fixed_block/
│       │   ├── fixed_block.gd        # Static solid obstacle
│       │   └── fixed_block.tscn
│       ├── shifting_block/
│       │   ├── shifting_block.gd     # Solid obstacle moving via Tween
│       │   └── shifting_block.tscn
│       ├── exit_point/
│       │   ├── exit_point.gd         # Area2D goal with occupancy detection & color swap
│       │   └── exit_point.tscn
│       ├── signal_gate/
│       │   ├── signal_gate.gd        # Node2D managing StaticBody2D gate + Area2D switch
│       │   └── signal_gate.tscn
│       └── danger_zone/
│           ├── fixed_danger_zone.gd    # Static lethal area (triggers Game Over)
│           ├── fixed_danger_zone.tscn
│           ├── shifting_danger_zone.gd # Patrolling lethal area
│           ├── shifting_danger_zone.tscn
│           ├── timed_danger_zone.gd    # Pulsing on/off lethal area
│           └── timed_danger_zone.tscn
│
├── prototype/
│   ├── prototype.tscn                # Gameplay scene (GameLauncher, Line2D, Env)
│   └── line_2d.gd                    # Connects all active player nodes dynamically
│
└── game_launcher/
    └── game_launcher.gd              # Orchestrates scene instantiation, camera, and win/fail rules
```

---

## 4. Level Data Schema (`levels_data/world_X/level_X_Y.json`)

Levels are authored in standard JSON loaded at runtime:

```json
{
  "w": [[0, 0], [1000, 600]],
  "p": [[200, 250], [200, 450]],
  "e": [[850, 200], [850, 450]],
  "o": {
    "fb": [[400, 250], [400, 400], [600, 200], [600, 450]],
    "sb": [[500, 320, 0]],
    "sg": [[700, 300, 300, 450]],
    "fd": [],
    "sd": [],
    "td": [[500, 320]]
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

### 5.1 Game Manager (`game_manager/game_manager.gd`)
Registered as an Autoload singleton (`GameManager`):
- Tracks `current_world` and `current_level`.
- Resolves level file paths dynamically: `res://levels_data/world_%d/level_%d_%d.json`.
- `load_level(world, level)`: Transitions to `prototype.tscn` to play the selected level.
- `restart_current_level()`: Reloads the active level.
- `get_next_level_info()`: Checks if next level exists in current world or next world.
- `load_next_level()`: Seamlessly transitions to the next available level.
- Navigation helpers: `go_to_level_select()`, `go_to_main_menu()`.

### 5.2 Game Launcher (`game_launcher/game_launcher.gd`)
Root orchestrator of gameplay inside `prototype.tscn`:
1. **Reads JSON:** Fetches data via `GameManager.get_current_level_json_data()`.
2. **Dialogs Overlay:** Instantiates `GameDialogs` as a `CanvasLayer` (layer 10) so modals remain fixed on screen.
3. **Walls Construction:** Generates 4 boundary walls sized and positioned to `levelData.windowSize`.
4. **Player Spawning:** Dynamically instantiates $N$ player scenes based on `"p"`.
5. **Camera Setup & Cycling:** Attaches `Camera2D` to player 1, sets limits to arena bounds, and cycles focus between players upon pressing `Tab`.
6. **Connecting Line:** Binds all player nodes to `Line2D` to draw the enclosing polygon.
7. **Win Condition:** Verifies all exit points are occupied by unique players. On completion, disables player movement and presents the Level Complete dialog.
8. **Loss Condition:** On contact with any danger zone, disables player movement and presents the Game Over dialog.

### 5.3 UI & Screen Flows
- **Homepage (`screens/main_menu/`):**
  - "Play" button -> transitions to Level Select screen.
  - "Exit" button -> quits application.
- **Level Select (`screens/level_select/`):**
  - Grouped by World 1 and World 2.
  - Clicking any level tile passes world and level number to `GameManager.load_level(world, level)`.
  - "< Back" button returns to Homepage.
- **In-Game Modals (`game_components/ui/game_dialogs.tscn`):**
  - **Game Over Dialog:** "Retry" (restarts level), "Levels" (level select), "Home" (main menu).
  - **Level Complete Dialog:** "Next Level" (loads next stage), "Retry", "Levels", "Home".

### 5.4 Game Components Reference
- **Player (`game_components/player/`):** `CharacterBody2D` (32×32) moving with normalized direction * 300.0 px/s.
- **Line2D (`prototype/line_2d.gd`):** Dynamic polygon connecting all active avatars.
- **Exit Points (`game_components/obstacles/exit_point/`):**
  - Size: 50×50 px.
  - Green when unoccupied, turns bright yellow upon player entry.
- **Signal Gate (`game_components/obstacles/signal_gate/`):**
  - Gate block (20×50, solid purple).
  - Remote switch (20×20, green). Stepping on the switch opens the gate (disables collision).
- **Danger Zones (`game_components/obstacles/danger_zone/`):**
  - Red hazards triggering Game Over on player collision.
  - Fixed, shifting (tween patrol), and timed (2s active / 2s inactive cycle).

---

## 6. Developer Guidelines for Future Extensions

### Adding New Worlds and Levels
1. Create a new folder under `res://levels_data/world_X/`.
2. Add JSON files matching the pattern `level_X_Y.json` (e.g. `level_3_1.json`).
3. Add a corresponding button in `screens/level_select/level_select.tscn` connecting to `_on_level_selected(X, Y)`.
4. `GameManager.get_next_level_info()` will automatically detect and link levels across worlds.

### Adding New Obstacles
1. Create scene and script under `res://game_components/obstacles/<new_obstacle>/`.
2. Register path in `util/file_names.gd`.
3. Add data class or array in `game_data_manager/sub_classes/level_data.gd`.
4. Parse in `game_data_manager/level_data_parser.gd`.
5. Spawn in `game_launcher/game_launcher.gd`.
