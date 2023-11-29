extends RigidBody3D


@onready var camera = $Camera3D

const MAX_SPEED = 10.0
const SPEED = 50.0
const JUMP_VELOCITY = 300

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * .005)
		camera.rotate_x(-event.relative.y * .005)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
func on_floor():
	const WORLD_MASK = 0b1
	var query = PhysicsRayQueryParameters3D.create(position, position + Vector3(0, -1, 0))
	query.collide_with_areas = true
	query.collision_mask = WORLD_MASK
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	return !result.is_empty()

func _integrate_forces(state):
	# Add the gravity.
	# TODO

	# Handle Jump. add on_floor check later
	if Input.is_action_just_pressed("jump"):
		Logger.trace("Player (%s) jumped with vel. y: " % [name, JUMP_VELOCITY])
		apply_force(Vector3.UP*JUMP_VELOCITY,global_transform.origin)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var start_velocity = linear_velocity.distance_to(Vector3.ZERO)
	if direction && start_velocity < MAX_SPEED:
		var force = Vector3(direction * SPEED)
		apply_force(force)
		Logger.trace("Moving Player %s with vel. x: %f z: %f" % [name, force.x, force.z])
	else:
		var x = move_toward(linear_velocity.x, 0, SPEED)
		var z = move_toward(linear_velocity.z, 0, SPEED)

