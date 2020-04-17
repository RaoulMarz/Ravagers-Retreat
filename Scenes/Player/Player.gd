extends KinematicBody2D

var max_speed_ticks = 0.3
var max_speed = 700
var max_run_speed = 1000
var damping_ratio = 1.3

var velocity = Vector2.ZERO
var move_momentum = Vector2.ZERO
var move_accel = max_speed / (max_speed_ticks / 1)
var run_accel = max_run_speed / (max_speed_ticks / 1)
var move_damping = move_accel * damping_ratio

func get_input(delta):

	var horizontal = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var vertical = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if abs(horizontal) >= 0.02 or abs(vertical) >= 0.02:
		move_momentum = Vector2(horizontal, -vertical)
	else:
		move_momentum = Vector2.ZERO
	# Apply damping
	if abs(horizontal) == 0 and abs(vertical) == 0: 
		if abs(velocity.x) > 0:
			velocity.x -= sign(velocity.x) * min(abs(velocity.x), delta * move_damping)
		if abs(velocity.y) > 0:
			velocity.y -= sign(velocity.y) * min(abs(velocity.y), delta * move_damping)
	
	# Smoothly change direction
#	if horizontal != 0 and sign(horizontal) != sign(velocity.x):
#		velocity.x = -velocity.x
#	if vertical != 0 and sign(vertical) != sign(velocity.y):
#		velocity.y = -velocity.y
	
	# Apply new move input
	var new_dir = Vector2(horizontal, vertical)
	if new_dir.length() > 1:
		new_dir = new_dir.normalized()
	
	var new_vel = new_dir * delta * move_accel
	velocity += new_vel
	
	if(velocity.length() > max_speed):
		velocity = velocity.normalized() * max_speed

func rotate_from_momentum(momentum):
	if momentum.length() > 0.2:
		var radials = momentum.angle_to(Vector2.DOWN)
		if abs(radials) > PI:
			radials = fmod(radials, PI)
		if abs(radials) - 0.001 <= 0:
			if sign(momentum.y) < 1:
				radials = PI
		rotation = radials

func _physics_process(delta):
	get_input(delta)
	rotate_from_momentum(move_momentum)
	velocity = move_and_slide(velocity, Vector2.UP)


func _on_VisibilityNotifier2D_screen_exited():
	velocity = -velocity
	if position.x <= 20:
		position.x = 20
	if position.y <= 20:
		position.y = 20
