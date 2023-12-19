extends Node
class_name MRCtl
## Movement and Rotation Control

var counter: int = 0
var updating_rotation: bool = false
var last_updated_rotation: Vector2
var target_rotation: Vector2
var pos_updated: bool = false
var old_vel: Vector3
var changed_vel = false

var _player: Player

func _ready():
	_player = get_parent()
	old_vel = _player.velocity

var pos_smooth: Vector3
var pos_diff: Vector3
func new_pos(new_pos: Vector3):
	pos_diff = new_pos - _player.position
	# Take 1 second to update
	pos_smooth = pos_diff

func remote_move(delta):
	if not _player.is_on_floor():
		_player.velocity.y -= _player.gravity * delta
	if pos_diff < pos_smooth * delta:
		pos_smooth = pos_diff
	_player.velocity += pos_smooth * delta
	pos_diff -= pos_smooth * delta
	_player.move_and_slide()
	
	if updating_rotation:
		var y_diff = target_rotation.y - _player.rotation.y
		if y_diff > PI:
			y_diff -= 2 * PI
		elif y_diff < -PI:
			y_diff += 2 * PI
		
		var x_diff = target_rotation.x - _player.camera.rotation.x
		if x_diff > PI:
			x_diff -= 2 * PI
		elif x_diff < -PI:
			x_diff += 2 * PI
			
		_player.rotate_y(y_diff / 16 + 0.005)
		_player.camera.rotate_x(x_diff / 16 + 0.005)
		if _player.rotation.y == target_rotation.y and _player.camera.rotation.x == target_rotation.x:
			updating_rotation = false

func local_move(delta):
	# This function will be called on each client for all _player instances.
	# This means that in a game with 4 _players, each client will have this function
	# called for all 4 _players, but we do not want the _player to control all 4
	# _players so we return early here.
	
	# Add the gravity.
	if not _player.is_on_floor():
		_player.velocity.y -= _player.gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and _player.is_on_floor():
		changed_vel = true
		Logger.trace("_player (%s) jumped with vel. y: %f" % [_player.name, _player.JUMP_VELOCITY])
		_player.velocity.y = _player.JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (_player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		_player.velocity.x = direction.x * _player.SPEED
		_player.velocity.z = direction.z * _player.SPEED
		Logger.trace("Moving _player %s with vel. x: %f z: %f" 
				  % [_player.name, _player.velocity.x, _player.velocity.z])
	else:
		_player.velocity.x = move_toward(_player.velocity.x, 0, _player.SPEED)
		_player.velocity.z = move_toward(_player.velocity.z, 0, _player.SPEED)
		
	_player.velocity.x = clamp(_player.velocity.x, -2 * _player.SPEED, 2 * _player.SPEED)
	_player.velocity.y = clamp(_player.velocity.y, -2 * _player.SPEED, 2 * _player.SPEED)
	_player.move_and_slide()
		
	counter += 1
	if counter == 128:
		counter = 0
		if updating_rotation:
			last_updated_rotation = Vector2(_player.camera.rotation.x, _player.rotation.y)
			_client_update_rotation.rpc(_player.camera.rotation.x, _player.rotation.y)
			updating_rotation = false
		if not pos_updated:
			Logger.info("fdjskl")
			pos_updated = true
			_server_update_pos.rpc(_player.position)
			return
	
	vel_updated = vel_updated or (changed_vel or old_vel.x != _player.velocity.x or old_vel.z != _player.velocity.z)
	if vel_updated:
		pos_updated = false
		accumulate += _player.velocity
		vel_counter += 1
		if vel_counter == 4:
			vel_updated = false
			old_vel = accumulate / vel_counter
			_server_update_vel.rpc(accumulate / vel_counter)
			vel_counter = 0
			accumulate = Vector3.ZERO

var vel_counter: int
var accumulate: Vector3 = Vector3.ZERO
var vel_updated: bool = false
@rpc("unreliable", "any_peer")
func _server_update_vel(vel: Vector3):
	_update_vel.rpc(vel)

@rpc("call_local", "unreliable", "authority")
func _update_vel(vel: Vector3):
	_player.velocity = vel
	_player.move_and_slide()

@rpc("unreliable", "any_peer")
func _server_update_pos(pos: Vector3):
	_update_pos.rpc(pos)

@rpc("call_local", "unreliable", "authority")
func _update_pos(pos: Vector3):
	Logger.info("%s" % (_player.position - pos))
	new_pos(pos)

func update_rotation(event):
	_player.rotate_y(-event.relative.x * _player.MOUSE_SPEED)
	_player.camera.rotate_x(-event.relative.y * _player.MOUSE_SPEED)
	_player.camera.rotation.x = clamp(_player.camera.rotation.x, -PI/2, PI/2)
	var diff = abs(last_updated_rotation.y - _player.rotation.y) \
			 + abs(last_updated_rotation.x - _player.camera.rotation.x)
	
	if (diff > 1) or (not updating_rotation and diff > .1):
		last_updated_rotation = Vector2(_player.camera.rotation.x, _player.rotation.y)
		updating_rotation = true
		_client_update_rotation.rpc(_player.camera.rotation.x, _player.rotation.y)

@rpc("any_peer", "unreliable", "call_remote")
func _client_update_rotation(x: float, y: float):
	updating_rotation = true
	target_rotation = Vector2(x, y)
