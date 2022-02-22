extends Kinematic

onready var state_timer = $Timers/StateTimer
onready var animation = $AnimationPlayer
onready var jump = $JumpDetector
onready var jump2 = $JumpDetector2
onready var sprite = $AnimatedSprite
onready var player_detector = $Detectors/PlayerDetector
var rng = RandomNumberGenerator.new()

enum state{
	REST,
	WALK,
	
	ATTACK
}

onready var start_point = global_position
var current_state = state.REST
var temp = 0

func _ready():
	set_time()

func _physics_process(delta: float):
	flip(direction.x)
	match(current_state):
		state.REST:
			animation.play("idle")
			velocity = calculate_velocity(velocity, Vector2(0.0, 1.0), speed)
		state.WALK:
			animation.play("walk")
			
			if abs(global_position.x - start_point.x) > 250:
				if temp == 0:
					temp = 1
					direction.x *= -1
			else:
				temp = 0
			
			velocity = calculate_velocity(velocity, direction, speed)
			
		state.ATTACK:
			animation.play("attack")
	
	velocity = move_and_slide(velocity, FLOOR_NORMAL)
	
	jump.force_raycast_update()
	jump2.force_raycast_update()
		
	if (jump.is_colliding() and jump2.is_colliding()):
		direction.x *= -1

func calculate_velocity(linear_velocity: Vector2, direction: Vector2, speed: Vector2):
	var out = linear_velocity
	
	
	if direction.x != 0:
		out.x = lerp(out.x, direction.x * speed.x, acceleration)
	else:
		out.x = lerp(out.x, 0, friction)
		
	out.y += gravity * get_physics_process_delta_time()
	
	if (!jump.is_colliding() and jump2.is_colliding() 
	and is_on_floor() and direction.x != 0 and state_timer.time_left > 0.2):
		out.y = speed.y * -1.0
	
	return out

func set_time():
	rng.randomize()
	var time = rng.randi_range(1, 4)
	state_timer.start(time)

func set_direction():
	rng.randomize()
	var new_direction = rng.randi_range(0, 1)
	
	if new_direction == 0:
		new_direction = -1
	
	return new_direction

func _on_StateTimer_timeout():
	if current_state == state.REST:
		direction.x = float(set_direction())
		current_state = state.WALK
	elif current_state == state.WALK:
		current_state = state.REST
	
	set_time()

func flip(direction: float):
	if direction != 0:
		sprite.scale.x = direction
		jump.cast_to.x = direction * 15
		jump2.cast_to.x = direction * 15
		jump.position.x = direction * 6
		jump2.position.x = direction * 6
		player_detector.scale.x = -direction


func _on_PlayerDetector_body_entered(body: Node):
	print(body)
	
func hurt():
	print("aug")
