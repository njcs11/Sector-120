# Paste this FULL replacement for HUD.gd
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
var escaped_label : Label = null

func _ready() -> void:
	escaped_label       = get_node_or_null("Control/EscapedLabel")
	msg_label.visible   = false
	go_panel.visible    = false
	boss_bar_bg.visible = false
	health_bar.max_value = 100
	health_bar.value    = 100
	_refresh_timer()
	if is_instance_valid(escaped_label):
		escaped_label.text    = "ESCAPED: 0 / 3"
		escaped_label.visible = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 1.0, 0.3)
	style.corner_radius_top_left    = 4
	style.corner_radius_top_right   = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("fill", style)

func _process(delta: float) -> void:
	if not is_counting:
		return
	time_remaining -= delta
	if time_remaining <= 0.0:
		time_remaining = 0.0
		is_counting    = false
		time_expired.emit()
	_refresh_timer()
	timer_label.modulate = Color(1, 0.2, 0.2) if time_remaining < 20.0 else Color.WHITE

func _refresh_timer() -> void:
	var total : int = int(time_remaining)
	var m : int = int(total / 60)
	var s : int = total % 60
	timer_label.text = "%d:%02d" % [m, s]

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
	var fill := health_bar.get_theme_stylebox("fill").duplicate()
	if pct > 0.6:
		fill.bg_color = Color(0.2, 1.0, 0.3)
	elif pct > 0.3:
		fill.bg_color = Color(1.0, 0.85, 0.1)
	else:
		fill.bg_color = Color(1.0, 0.2, 0.2)
	health_bar.add_theme_stylebox_override("fill", fill)

func update_wave(w: int, t: int) -> void:
	wave_label.text = "WAVE %d/%d" % [w, t]

func update_score(s: int) -> void:
	score_label.text = "SCORE  %d" % s

func update_escaped(count: int, max_count: int) -> void:
	if not is_instance_valid(escaped_label): return
	escaped_label.text = "ESCAPED: %d / %d" % [count, max_count]
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
	go_panel.visible = true
	if won:
		go_result.text     = "✓  MISSION COMPLETE!"
		go_result.modulate = Color(0.3, 1.0, 0.4)
	else:
		go_result.text     = "✗  MISSION FAILED"
		go_result.modulate = Color(1.0, 0.3, 0.3)
	go_score.text = "Score:  %d" % s
	go_hint.text  = "Press Enter to Restart"
