# HUD.gd — Full replacement
extends CanvasLayer

signal time_expired

const GAME_DURATION := 210.0
var time_remaining  := GAME_DURATION
var is_counting     := false

@onready var timer_label   : Label          = $Control/TimerLabel
@onready var wave_label    : Label          = $Control/WaveLabel
@onready var score_label   : Label          = $Control/ScoreLabel
@onready var health_bar    : ProgressBar    = $Control/HealthBar
@onready var hp_label      : Label          = $Control/HPLabel
@onready var msg_label     : Label          = $Control/MsgLabel
@onready var go_panel      : PanelContainer = $Control/GameOverPanel
@onready var go_result     : Label          = $Control/GameOverPanel/VBox/ResultLabel
@onready var go_score      : Label          = $Control/GameOverPanel/VBox/ScoreLabel
@onready var go_hint       : Label          = $Control/GameOverPanel/VBox/HintLabel
@onready var boss_bar_bg   : Panel          = $Control/BossBarBG
@onready var boss_bar      : ProgressBar    = $Control/BossBarBG/BossBar
@onready var boss_label    : Label          = $Control/BossBarBG/BossLabel
@onready var retry_btn     : Button         = $Control/GameOverPanel/VBox/ButtonRow/RetryButton
@onready var menu_btn      : Button         = $Control/GameOverPanel/VBox/ButtonRow/MainMenuButton
@onready var pause_panel   : PanelContainer = $Control/PausePanel
@onready var continue_btn  : Button         = $Control/PausePanel/VBox/ContinueButton
@onready var pause_menu_btn: Button         = $Control/PausePanel/VBox/PauseMenuButton

var retry_menu_btn : Button = null
var escaped_label  : Label  = null

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	# ── CRITICAL: HUD must keep processing even when tree is paused ──────
	# Without this, _process() stops → ESC key won't work, timer code below
	# won't run. The timer check inside _process() already guards with
	# is_counting, so nothing ticks unless we allow it.
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Safe optional nodes
	escaped_label  = get_node_or_null("Control/EscapedLabel")
	retry_menu_btn = get_node_or_null("Control/PausePanel/VBox/RetryMenuButton")

	# Initial visibility
	msg_label.visible   = false
	go_panel.visible    = false
	boss_bar_bg.visible = false
	pause_panel.visible = false

	# Health bar setup
	health_bar.max_value = 100
	health_bar.value     = 100
	_refresh_timer()
	_apply_health_style(Color(0.2, 1.0, 0.3))

	# Escaped label
	if is_instance_valid(escaped_label):
		escaped_label.text    = "ESCAPED: 0 / 3"
		escaped_label.visible = true

	# Connect Game-Over buttons
	retry_btn.pressed.connect(_on_retry)
	menu_btn.pressed.connect(_on_main_menu)

	# Connect Pause buttons
	continue_btn.pressed.connect(_on_continue)
	pause_menu_btn.pressed.connect(_on_main_menu)

	if is_instance_valid(retry_menu_btn):
		retry_menu_btn.pressed.connect(_on_retry)

# ─────────────────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	# ESC input — always checked (process_mode = ALWAYS lets this run while paused)
	if Input.is_action_just_pressed("ui_cancel") and not go_panel.visible:
		_toggle_pause()

	# ── Timer only ticks when game is NOT paused AND is_counting is true ──
	# get_tree().paused check here is the key fix:
	# _process runs because PROCESS_MODE_ALWAYS, but we manually skip
	# the countdown while paused so time doesn't advance.
	if not is_counting or get_tree().paused:
		return

	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		is_counting    = false
		time_expired.emit()

	_refresh_timer()
	timer_label.modulate = Color(1, 0.2, 0.2) if time_remaining < 20.0 else Color.WHITE

# ─────────────────────────────────────────────────────────────────────────────
func _refresh_timer() -> void:
	var total : int = int(time_remaining)
	var m : int     = total / 60
	var s : int     = total % 60
	timer_label.text = "%d:%02d" % [m, s]

func _apply_health_style(col: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color               = col
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("fill", style)

# ─────────────────────────────────────────────────────────────────────────────
# PUBLIC API
# ─────────────────────────────────────────────────────────────────────────────
func start_timer() -> void:
	time_remaining = GAME_DURATION
	is_counting    = true

func stop_timer() -> void:
	is_counting = false

func update_health(cur: int, mx: int) -> void:
	health_bar.max_value = mx
	health_bar.value     = cur
	hp_label.text        = "HP  %d / %d" % [cur, mx]
	var pct := float(cur) / float(mx)
	if pct > 0.6:
		_apply_health_style(Color(0.2, 1.0, 0.3))
	elif pct > 0.3:
		_apply_health_style(Color(1.0, 0.85, 0.1))
	else:
		_apply_health_style(Color(1.0, 0.2, 0.2))

func update_wave(w: int, t: int) -> void:
	wave_label.text = "WAVE %d/%d" % [w, t]

func update_score(s: int) -> void:
	score_label.text = "SCORE  %d" % s

func update_escaped(count: int, max_count: int) -> void:
	if not is_instance_valid(escaped_label):
		return
	escaped_label.text     = "ESCAPED: %d / %d" % [count, max_count]
	escaped_label.modulate = Color(1.0, 0.2, 0.2)
	await get_tree().create_timer(0.4).timeout
	escaped_label.modulate = Color.WHITE

func show_boss_bar(visible_state: bool) -> void:
	boss_bar_bg.visible = visible_state

func update_boss_health(cur: int, mx: int) -> void:
	boss_bar.max_value = mx
	boss_bar.value     = cur
	boss_label.text    = "KRAKEN  %d / %d" % [cur, mx]

func show_message(txt: String, dur: float = 2.0) -> void:
	msg_label.text    = txt
	msg_label.visible = true
	await get_tree().create_timer(dur).timeout
	msg_label.visible = false

func show_game_over(won: bool, s: int) -> void:
	stop_timer()
	get_tree().paused   = false
	pause_panel.visible = false
	go_panel.visible    = true
	if won:
		go_result.text     = "MISSION COMPLETE"
		go_result.modulate = Color(0.3, 1.0, 0.4)
	else:
		go_result.text     = "MISSION FAILED"
		go_result.modulate = Color(1.0, 0.3, 0.3)
	go_score.text = "Score:  %d" % s
	go_hint.text  = ""

# ─────────────────────────────────────────────────────────────────────────────
# PAUSE
# ─────────────────────────────────────────────────────────────────────────────
func _toggle_pause() -> void:
	get_tree().paused   = not get_tree().paused
	pause_panel.visible = get_tree().paused

func _on_continue() -> void:
	get_tree().paused   = false
	pause_panel.visible = false

# ─────────────────────────────────────────────────────────────────────────────
# BUTTON CALLBACKS
# ─────────────────────────────────────────────────────────────────────────────
func _on_retry() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
