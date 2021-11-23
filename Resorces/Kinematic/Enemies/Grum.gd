extends Kinematic

onready var state_timer = $Timers/StateTimer
onready var animation = $AnimationPlayer
onready var jump = $JumpDetector
onready var jump2 = $JumpDetector2
onready var sprite = $AnimatedSprite
var rng = RandomNumberGenerator.new()

enum state{
	IDLE,
	WALK,
	ATTACK
}

onready var start_point = global_position
var current_state = state.IDLE

func _ready():
	set_time()

func _physics_process(delta: float):
	match(current_state):
		state.IDLE:
			animation.play("idle")
			velocity = calculate_velocity(velocity, direction, speed)
		state.WALK:
			animation.play("walk")
			#if abs(global_position.x - start_point.x) < 100:
			velocity = calculate_velocity(velocity, direction, speed)
			#else:
			#	_on_StateTimer_timeout()
			
		state.ATTACK:
			animation.play("attack")
	
	velocity = move_and_slide(velocity, FLOOR_NORMAL)
	
	jump.force_raycast_update()
	jump2.force_raycast_update()
		
	if (jump.is_colliding() and jump2.is_colliding()):
		direction.x *= -1

func calculate_velocity(linear_velocity: Vector2, direction: Vector2, speed: Vector2):
	var out = linear_velocity
	
	out.x = direction.x * speed.x
	out.y += gravity * get_physics_process_delta_time()
	
	return out

func set_time():
	rng.randomize()
	var time = rng.randi_range(1, 2)
	state_timer.start(time)

func set_direction():
	rng.randomize()
	var new_direction = rng.randi_range(0, 1)
	
	if new_direction == 0:
		new_direction = -1
	
	return new_direction

func _on_StateTimer_timeout():
	if current_state == state.IDLE:
		direction.x = float(set_direction())
		flip(direction.x)
		current_state = state.WALK
	elif current_state == state.WALK:
		direction = Vector2(0.0, 1.0)
		current_state = state.IDLE
	
	set_time()

func flip(direction: float):
	sprite.scale.x = direction
	jump.cast_to.x = direction * 10
	jump2.cast_to.x = direction * 10
	jump.position.x = direction * 6
	jump2.position.x = direction * 6
