extends Node

signal bgm_toggled(is_muted: bool)
signal sfx_toggled(is_muted: bool)

const AUDIO_SETTINGS_PATH: String = "user://audio_settings.json"

# ── Audio Streams ─────────────────────────────────────────────────────────────
const BGM_STREAM = preload("res://audio/bgm/cyber_ambience.wav")
const UI_CLICK_STREAM = preload("res://audio/sfx/ui_click.wav")
const UI_HOVER_STREAM = preload("res://audio/sfx/ui_hover.wav")
const THRUSTER_STREAM = preload("res://audio/sfx/player_thruster.wav")
const PORTAL_ENTER_STREAM = preload("res://audio/sfx/portal_enter.wav")
const PORTAL_LEAVE_STREAM = preload("res://audio/sfx/portal_leave.wav")
const GATE_TOGGLE_STREAM = preload("res://audio/sfx/gate_toggle.wav")
const HAZARD_BREACH_STREAM = preload("res://audio/sfx/hazard_breach.wav")
const GAME_OVER_STREAM = preload("res://audio/sfx/game_over.wav")
const LEVEL_COMPLETE_STREAM = preload("res://audio/sfx/level_complete.wav")

# ── Audio Players ─────────────────────────────────────────────────────────────
var _bgm_player: AudioStreamPlayer
var _thruster_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE: int = 8
var _sfx_index: int = 0

var _is_thruster_active: bool = false
var _thruster_volume: float = -80.0

var is_bgm_muted: bool = false
var is_sfx_muted: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	_setup_audio_players()
	_hook_tree_buttons()
	if not is_bgm_muted:
		play_bgm()

func _setup_audio_players() -> void:
	# 1. Background Music Player (Seamless Looping)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	_bgm_player.bus = "Master"
	var bgm_stream = BGM_STREAM.duplicate()
	if bgm_stream is AudioStreamWAV:
		bgm_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		bgm_stream.loop_begin = 0
		bgm_stream.loop_end = int(bgm_stream.get_length() * bgm_stream.mix_rate)
	_bgm_player.stream = bgm_stream
	_bgm_player.volume_db = -8.0
	add_child(_bgm_player)

	# 2. Movement Thruster Player (Seamless Looping with volume fade)
	_thruster_player = AudioStreamPlayer.new()
	_thruster_player.name = "ThrusterPlayer"
	var thruster_stream = THRUSTER_STREAM.duplicate()
	if thruster_stream is AudioStreamWAV:
		thruster_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		thruster_stream.loop_begin = 0
		thruster_stream.loop_end = int(thruster_stream.get_length() * thruster_stream.mix_rate)
	_thruster_player.stream = thruster_stream
	_thruster_player.volume_db = -80.0
	add_child(_thruster_player)
	_thruster_player.play()

	# 3. UI SFX Player
	_ui_player = AudioStreamPlayer.new()
	_ui_player.name = "UIPlayer"
	add_child(_ui_player)

	# 4. Polyphonic SFX Pool
	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		add_child(p)
		_sfx_players.append(p)

func _process(delta: float) -> void:
	if is_sfx_muted:
		_thruster_volume = -80.0
		if _thruster_player:
			_thruster_player.volume_db = -80.0
		return

	# Smoothly crossfade thruster hum based on player velocity
	var target_db = -10.0 if _is_thruster_active else -80.0
	_thruster_volume = lerpf(_thruster_volume, target_db, delta * 12.0)
	if _thruster_player:
		_thruster_player.volume_db = _thruster_volume

# ── Settings Persistence ──────────────────────────────────────────────────────

func save_settings() -> void:
	var data: Dictionary = {
		"bgm_muted": is_bgm_muted,
		"sfx_muted": is_sfx_muted
	}
	var f = FileAccess.open(AUDIO_SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func load_settings() -> void:
	if not FileAccess.file_exists(AUDIO_SETTINGS_PATH):
		return
	var f = FileAccess.open(AUDIO_SETTINGS_PATH, FileAccess.READ)
	if not f:
		return
	var content = f.get_as_text()
	f.close()
	var json = JSON.new()
	if json.parse(content) == OK and json.data is Dictionary:
		var d: Dictionary = json.data
		if d.has("bgm_muted"):
			is_bgm_muted = bool(d["bgm_muted"])
		if d.has("sfx_muted"):
			is_sfx_muted = bool(d["sfx_muted"])

# ── Thruster Controls ─────────────────────────────────────────────────────────

func set_thruster_active(active: bool) -> void:
	_is_thruster_active = active

# ── BGM Controls & Toggle ─────────────────────────────────────────────────────

func toggle_bgm() -> bool:
	set_bgm_muted(not is_bgm_muted)
	return is_bgm_muted

func set_bgm_muted(muted: bool) -> void:
	is_bgm_muted = muted
	if _bgm_player:
		if is_bgm_muted:
			_bgm_player.stream_paused = true
		else:
			_bgm_player.stream_paused = false
			if not _bgm_player.playing:
				_bgm_player.play()
	save_settings()
	bgm_toggled.emit(is_bgm_muted)

func play_bgm() -> void:
	if is_bgm_muted:
		return
	if _bgm_player:
		_bgm_player.stream_paused = false
		if not _bgm_player.playing:
			_bgm_player.play()

func stop_bgm() -> void:
	if _bgm_player:
		_bgm_player.stop()

# ── SFX Controls & Toggle ─────────────────────────────────────────────────────

func toggle_sfx() -> bool:
	set_sfx_muted(not is_sfx_muted)
	return is_sfx_muted

func set_sfx_muted(muted: bool) -> void:
	is_sfx_muted = muted
	if is_sfx_muted:
		_thruster_volume = -80.0
		if _thruster_player:
			_thruster_player.volume_db = -80.0
		if _ui_player:
			_ui_player.stop()
		for p in _sfx_players:
			p.stop()
	save_settings()
	sfx_toggled.emit(is_sfx_muted)

# ── UI SFX ────────────────────────────────────────────────────────────────────

func play_ui_click() -> void:
	if is_sfx_muted or not _ui_player:
		return
	_ui_player.stream = UI_CLICK_STREAM
	_ui_player.volume_db = -3.0
	_ui_player.play()

func play_ui_hover() -> void:
	if is_sfx_muted or not _ui_player:
		return
	if not _ui_player.playing or _ui_player.stream == UI_HOVER_STREAM:
		_ui_player.stream = UI_HOVER_STREAM
		_ui_player.volume_db = -12.0
		_ui_player.play()

# ── Gameplay SFX ──────────────────────────────────────────────────────────────

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if is_sfx_muted:
		return
	var player = _sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.volume_db = volume_db
	player.play()

func play_portal_enter() -> void:
	play_sfx(PORTAL_ENTER_STREAM, -2.0)

func play_portal_leave() -> void:
	play_sfx(PORTAL_LEAVE_STREAM, -4.0)

func play_gate_toggle() -> void:
	play_sfx(GATE_TOGGLE_STREAM, -3.0)

func play_hazard_breach() -> void:
	play_sfx(HAZARD_BREACH_STREAM, 0.0)

func play_game_over() -> void:
	set_thruster_active(false)
	play_sfx(GAME_OVER_STREAM, 2.0)

func play_level_complete() -> void:
	set_thruster_active(false)
	play_sfx(LEVEL_COMPLETE_STREAM, 2.0)

# ── Global Button Hooking ─────────────────────────────────────────────────────

func _hook_tree_buttons() -> void:
	get_tree().node_added.connect(_on_node_added)
	_hook_buttons_in_node(get_tree().root)

func _on_node_added(node: Node) -> void:
	if node is Button:
		_hook_button(node)

func _hook_buttons_in_node(node: Node) -> void:
	if node is Button:
		_hook_button(node)
	for child in node.get_children():
		_hook_buttons_in_node(child)

func _hook_button(button: Button) -> void:
	if not button.has_meta("__sound_hooked"):
		button.set_meta("__sound_hooked", true)
		button.pressed.connect(play_ui_click)
		button.mouse_entered.connect(play_ui_hover)
