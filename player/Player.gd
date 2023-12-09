extends CharacterBody3D

@onready var camera = $Camera3D

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 3
@export var MOUSE_SPEED = 0.0015
@export var INTERACTION_DISTANCE = 100
var client_id: int


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	Logger.debug("_enter_tree: Setting multiplayer authority to %s for self" \
				% name)
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority():
		Logger.trace("_ready: Local is not authority for %s, skipping _ready()" \
					% name)
		return
	
	Logger.debug("_ready: Local is authority for %s, capturing mouse and setting \
				  current camera" % name)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SPEED)
		camera.rotate_x(-event.relative.y * MOUSE_SPEED)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		return
	
	if event.is_action_pressed("interact"):
		Logger.debug("_unhandled_input: Player pressed interact button")
		interact()

## Players interact function. If an interactive object is found, it will be
## sent to that object's interact function. See [method item.interact]
func interact():
	const ITEM_MASK = 0b100
	var origin = camera.project_ray_origin(Vector2.ZERO)
	var end = origin + camera.project_ray_normal(Vector2.ZERO) * INTERACTION_DISTANCE
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collision_mask = ITEM_MASK
	
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		Logger.debug("Player.interact: No item found in raycast")
		return
	
	if check_valid_method(result["collider"], "interact", []):
		result["collider"].interact()
		
## Check for a valid method on the object matching method name and args
## (`<object>.<method_name>(<args>)`)
func check_valid_method(
	object: Object, 
	method_name: String, 
	## Array of arguments to the function. No args would be []
	args: Array
) -> bool:
		Logger.debug("Player.check_valid_method: checking functionality on %s"\
				  % object)
		for method in object.get_method_list():
			if method["name"] == method_name:
				if method["args"] == args:
					Logger.debug("Player.check_valid_method: Valid method found") 
					return true
				else:
					Logger.debug("Player.check_valid_method: (args) %s != %s" \
								% [method["args"], args])
			else:
				Logger.trace("Player.check_valid_method: %s != %s"\
							% [method["name"], method_name])
		
		return false

@onready var floor_check = $FloorCheck
var on_floor = false
func update_on_floor():
	on_floor = floor_check.get_overlapping_bodies()

func _physics_process(delta):
	# This function will be called on each client for all player instances.
	# This means that in a game with 4 players, each client will have this function
	# called for all 4 players, but we do not want the player to control all 4
	# players so we return early here.
	if not is_multiplayer_authority(): return

	var input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		Logger.trace("Player (%s) jumped with vel. y: %f" % [name, JUMP_VELOCITY])
		velocity.y += JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		Logger.trace("Moving Player %s with vel. x: %f z: %f" % [name, velocity.x, velocity.z])
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	update_on_floor()
	Logger.info("vel: %s" % velocity)
	if on_floor and velocity.y < 0:
		velocity.y = 0
	else:
		Logger.info("gravity")
		velocity.y -= gravity / 100
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collision_amount = collision.get_collision_count()
		for i in range(collision_amount):
			var collider = collision.get_collider(i)
			if collider is RigidBody3D:
				var is_ground = collider.collision_layer == 0x1
				var angle = collision.get_angle(i)
				var normal = collision.get_normal(i)
				collider.apply_force(1000 * normal)
				Logger.info("%s, %s" % [angle, normal])
