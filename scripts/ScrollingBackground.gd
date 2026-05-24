extends Node2D

@export var scroll_speed : float = 90.0
@export var bg_width     : float = 1280.0

@onready var bg1 : Sprite2D = $Background1
@onready var bg2 : Sprite2D = $Background2

func _ready() -> void:
	bg1.position = Vector2.ZERO
	bg2.position = Vector2(bg_width, 0.0)

func _process(delta: float) -> void:
	bg1.position.x -= scroll_speed * delta
	bg2.position.x -= scroll_speed * delta
	if bg1.position.x <= -bg_width:
		bg1.position.x = bg2.position.x + bg_width
	if bg2.position.x <= -bg_width:
		bg2.position.x = bg1.position.x + bg_width
