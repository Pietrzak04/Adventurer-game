extends Camera2D

onready var parent = get_parent()

export var camera_offset = 32
export var time_to_move = 1.0

var side = Vector2.ZERO
var timer

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	timer.connect("timeout", self, "button_timeout")
	add_child(timer)

func _process(delta: float):
	if parent.velocity.length() > 0:
		reset_camera()

func _input(event: InputEvent):
	
	if event.is_action_pressed("camera_up"):
		side = Vector2.UP
		timer.start(time_to_move)
	
	if event.is_action_pressed("camera_down"):
		side = Vector2.DOWN
		timer.start(time_to_move)
	
	if event.is_action_pressed("camera_left"):
		side = Vector2.LEFT
		timer.start(time_to_move)
	
	if event.is_action_pressed("camera_right"):
		side = Vector2.RIGHT
		timer.start(time_to_move)
	
	if event.is_action_released("camera_up") or event.is_action_released("camera_down") or event.is_action_released("camera_left") or event.is_action_released("camera_right"):
		reset_camera()

func move_camera(side: Vector2):
	position = side * camera_offset

func reset_camera():
	timer.stop()
	position = Vector2.ZERO

func button_timeout():
	move_camera(side)
