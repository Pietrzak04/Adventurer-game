extends Kinematic

const PLAYER_SIZE = Vector2(50, 37)
const FLOOR_DETECT_DISTANCE = 4.0

onready var animation_tree = $AnimationTree
onready var sprite = $AnimatedSprite
onready var vertical = $Grabing/Vertical
onready var invertical = $Grabing/InversedVertical
onready var grabing_node = $Grabing
onready var groundl = $Ground/GroundLeft
onready var groundr = $Ground/GroundRight
onready var col = $NormalColision
onready var crouch_col = $CrouchColision
onready var crouch_detector = $CrouchDetector
onready var attack_time = $Timers/AttackTimer

export var crouch_speed = Vector2(50.0, 200.0)

enum state {
	MOVEMENT,
	ANIMATION,
	GRABING,
	CROUCHING,
	ATTACK,
}

var current_state = state.MOVEMENT

var position_in_animation = Vector2.ZERO
var animation_moveing_speed = 0.0

var on_ground = true
var jump_count = 0
var double_jump = false

var crouch_space = 0
var attack_count = 0
var attack_interrupt = false

func get_direction():
	return Vector2(Input.get_action_strength("right") - Input.get_action_strength("left"),
	 -1.0 if Input.is_action_just_pressed("up") else 1.0)

func grab(linear_velocity: Vector2):
	
	if linear_velocity.y > 0:
		
		vertical.force_raycast_update()
		invertical.force_raycast_update()
		
		if vertical.is_colliding() and !invertical.is_colliding():
			var new_position = global_position
			new_position.y = vertical.get_collision_point().y + 31.45
			global_position = new_position
			current_state = state.GRABING
		
		if invertical.is_colliding() or is_on_floor():
			vertical.set_collision_mask_bit(0, 1)

func crouch():
	col.set_deferred("disabled", true)
	crouch_col.set_deferred("disabled", false)
	current_state = state.CROUCHING

func stand():
	col.set_deferred("disabled", false)
	crouch_col.set_deferred("disabled", true)
	current_state = state.MOVEMENT

func attack_ended():
	current_state = state.MOVEMENT
	attack_count = 0
	attack_interrupt = false

func flip(direction: Vector2):
	if direction.x != 0.0:
		grabing_node.scale.x = direction.x
		sprite.scale.x = direction.x

func _input(event: InputEvent):
	
	match(current_state):
		state.MOVEMENT:
			
			if event.is_action_pressed("up"):
				if jump_count == 1:
					double_jump = true
			if event.is_action_pressed("down"):
				crouch()
			if event.is_action_pressed("attack"):
				animation_tree.set("parameters/AttackType/current", int(!is_on_floor()))
				current_state = state.ATTACK
			
		state.CROUCHING:
			
			if event.is_action_released("down") and crouch_space == 0:
				stand()
			
		state.GRABING:
			
			if event.is_action_pressed("up"):
				jump_count = 0
				double_jump = false
				animation_tree.set("parameters/Grabbing/current", 1)
			if event.is_action_pressed("down"):
				vertical.set_collision_mask_bit(0, 0)
				velocity = Vector2.ZERO
				current_state = state.MOVEMENT
				
		state.ATTACK:
			if event.is_action_pressed("attack") and attack_time.is_stopped():
				attack_interrupt = true
			
			if event.is_action_pressed("attack") and attack_time.time_left > 0.0 and !attack_interrupt:
				attack_count += 1

func _process(delta: float):
	match(current_state):
		state.MOVEMENT:
			animation_tree.set("parameters/State/current", int(!is_on_floor()))
			animation_tree.set("parameters/Air/current", int(velocity.y > 0))
			animation_tree.set("parameters/DoubleJump/current", double_jump)
			animation_tree.set("parameters/Movement/current", abs(direction.x) * int(!is_on_wall()))
			animation_tree.set("parameters/Grabbing/current", 0)
		
		state.GRABING:
			animation_tree.set("parameters/State/current", 2)
		
		state.CROUCHING:
			animation_tree.set("parameters/State/current", 4) if is_on_floor() else animation_tree.set("parameters/State/current", 1)
			animation_tree.set("parameters/Air/current", int(velocity.y > 0))
			animation_tree.set("parameters/MovementCrouch/current", int(abs(direction.x) * int(!is_on_wall())))
		
		state.ATTACK:
			animation_tree.set("parameters/State/current", 5)
			animation_tree.set("parameters/AttackNumber/current", attack_count)

func _physics_process(delta: float):
	match(current_state):
		state.MOVEMENT:
			
			direction = get_direction()
			flip(direction)
			
			var is_jump_interrupted: = Input.is_action_just_released("up") and velocity.y < 0.0
			var snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE if direction.y == 0.0 else Vector2.ZERO
			var is_on_platform = groundl.is_colliding() or groundr.is_colliding()
			
			velocity = calculate_move_velocity(velocity, speed, direction, is_jump_interrupted)
			velocity = move_and_slide_with_snap(velocity, snap_vector, FLOOR_NORMAL, not is_on_platform, 4,  0.9, false)
			
			grab(velocity)
			
		state.ANIMATION:
			
			velocity = position.direction_to(position_in_animation) * animation_moveing_speed
			
			if position.distance_to(position_in_animation) > 1:
				velocity = move_and_slide(velocity)
		
		state.CROUCHING:
			direction = get_direction()
			flip(direction)
			
			var snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE if direction.y == 0.0 else Vector2.ZERO
			var is_on_platform = groundl.is_colliding() or groundr.is_colliding()
			
			velocity = calculate_move_velocity(velocity, crouch_speed, direction, false , false)
			velocity = move_and_slide_with_snap(velocity, snap_vector, FLOOR_NORMAL, not is_on_platform, 4,  0.9, false)
		
		state.ATTACK:
			direction = Vector2.DOWN if is_on_floor() else Vector2(get_direction().x, 1)
			
			var snap_vector = Vector2.DOWN * FLOOR_DETECT_DISTANCE if direction.y == 0.0 else Vector2.ZERO
			var is_on_platform = groundl.is_colliding() or groundr.is_colliding()
			
			velocity = calculate_move_velocity(velocity, speed, direction, false, false)
			velocity = move_and_slide_with_snap(velocity, snap_vector, FLOOR_NORMAL, not is_on_platform, 4,  0.9, false)

func in_animation_move(move_distance: Vector2, speed: float):
	position_in_animation.y = position.y + move_distance.y
	position_in_animation.x = position.x + move_distance.x * sprite.scale.x
	animation_moveing_speed = speed
	current_state = state.ANIMATION

func animation_ended(state: int):
	position_in_animation = Vector2.ZERO
	velocity = Vector2.ZERO
	current_state = state

func calculate_move_velocity(linear_velocity: Vector2, speed: Vector2, direction: Vector2, is_jump_interrupted = false, double_jump_eneabled = true):
	var out: = linear_velocity
	
	if direction.x != 0:
		out.x = lerp(out.x, direction.x * speed.x, acceleration)
	else:
		out.x = lerp(out.x, 0, friction)
	
	out.y += gravity * get_physics_process_delta_time()
	
	if direction.y == -1.0:
		if jump_count < 2:
			jump_count += 1
			on_ground = false
			out.y = speed.y * direction.y
	
	if is_jump_interrupted:
		out.y *= 0.6
	
	if is_on_floor():
		double_jump = false
		if on_ground == false:
			on_ground = true
			jump_count = 0
	else:
		if on_ground == true:
			on_ground = false
			jump_count = 1 if double_jump_eneabled else 2
	
	if out.y > 600:
		out.y = 600
	
	return out

func crouchDetector_body_exited(body: Node):
	crouch_space -=1
	
	if crouch_space == 0 and !Input.is_action_pressed("down"):
		stand()

func crouchDetector_body_entered(body: Node):
	crouch_space +=1

func AttackBox_area_entered(area: Area2D):
	area.owner.hurt()
