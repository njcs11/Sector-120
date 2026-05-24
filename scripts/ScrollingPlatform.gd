extends StaticBody2D
# ScrollingPlatform.gd — moves left with background, respawns on right

@export var scroll_speed : float = 95.0
@export var screen_width : float = 1280.0

var _start_x : float = 0.0

const PLATFORM_Y_SLOTS : Array = [480.0, 510.0, 540.0]
var _slot_index : int = 0

func _ready() -> void:
	_start_x = global_position.x

func _process(delta: float) -> void:
	global_position.x -= scroll_speed * delta
	if global_position.x < -200.0:
		global_position.x  = screen_width + randf_range(180.0, 480.0)
		_slot_index        = (_slot_index + 1) % PLATFORM_Y_SLOTS.size()
		global_position.y  = PLATFORM_Y_SLOTS[_slot_index]
