extends CharacterBody3D
class_name Player

@onready var camera: Camera3D = $Camera3D
@onready var healthbar: TextureProgressBar = $Healthbar
@onready var inventory_control: InventoryGUICtrl = $UI/InventoryControl
@onready var inventory_gui: InventoryGUI = $UI/InventoryGUI
@onready var wictl: WICtl = $WICtl
@onready var server_global: ServerGlobal = get_node("/root/ServerGlobal")
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 3
@export var MOUSE_SPEED = 0.0015
@export var maxHealth: int = 100
var client_id: int
var health: int = maxHealth : set = set_health 
var counter: int = 0
var updating_rotation: bool = false
var last_updated_rotation: Vector2
var target_rotation: Vector2

## If this player instance is the one for the client. Obviously do not sync this.
var _client_is_player: bool = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	_client_is_player = name == str(multiplayer.get_unique_id())
	if _client_is_player: Logger.debug("Setting player %s to %s" % [name, multiplayer.get_unique_id()])

func _ready():
	if not _client_is_player:
		Logger.trace("_ready: Local is not authority for %s, skipping _ready()" \
					% name)
		return
	
	Logger.debug("_ready: Local is authority for %s, capturing mouse and setting \
				  current camera" % name)
	
	inventory_control.update(wictl.inventory.items)
	inventory_control.player = self
	inventory_gui.inv_owner = self
	wictl.inventory.owner = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	healthbar.value = health
	wictl.inventory.items = server_global.generate_test_inv()

func _unhandled_input(event):
	if not _client_is_player: return
	
	if event is InputEventMouseMotion:
		_update_rotation(event)
	elif event.is_action_pressed("interact") and not event.is_echo():
		# TEST for damage system
		# damage(10)
		Logger.debug("_unhandled_input: Player pressed interact button")
		interact()
	elif event.is_action_pressed("open_inventory") and not event.is_echo():
		if inventory_control.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			inventory_gui.hide()
			inventory_control.hide()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			var viewport = DisplayServer.window_get_size()
			inventory_control.update(wictl.inventory.items)
			inventory_gui.position = Vector2(viewport.x/2, viewport.y/2)
			inventory_control.show()
			inventory_gui.show()
	# TEST for heal system. Jump is handled in [method _physics_process]
	elif event.is_action_pressed("jump"):
		heal(10)

func _update_rotation(event):
	rotate_y(-event.relative.x * MOUSE_SPEED)
	camera.rotate_x(-event.relative.y * MOUSE_SPEED)
	camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	var diff = abs(last_updated_rotation.y - rotation.y) \
			 + abs(last_updated_rotation.x - camera.rotation.x)
	
	if (diff > 1) or (not updating_rotation and diff > .1):
		last_updated_rotation = Vector2(camera.rotation.x, rotation.y)
		updating_rotation = true
		_client_update_rotation.rpc(camera.rotation.x, rotation.y)

@rpc("any_peer", "unreliable", "call_remote")
func _client_update_rotation(x: float, y: float):
	Logger.debug("%s updating rotation" % multiplayer.get_unique_id())
	updating_rotation = true
	target_rotation = Vector2(x, y)

func drop_item(item: ItemWrapper) -> void:
	Logger.debug("Player.drop_item: Dropping %s (quantity %d)" % [item.item_type.name, item.quantity])
	if inventory_control.delete_or_reduce(item) == 0:
		wictl.drop_item(item)

## Damages through [method set_health]. If health < 0, [method death] will be called.
func damage(dmg: int):
	Logger.info("Player took %s damage." % dmg)
	_server_update_health.rpc_id(1, -dmg)
	
## Heals through [method set_health]. Health will be clamped to maxHealth.
func heal(hl: int):
	_server_update_health.rpc_id(1, hl)

@rpc("any_peer", "reliable")
func _server_update_health(hl_change: int):
	health += hl_change
	_update_health.rpc(health)

@rpc("authority", "reliable", "call_local")
func _update_health(player_health: int):
	health = player_health

## Called whenever the player's health changes.
func set_health(newHealth: int):
	# Ensure that the player's health doesn't go below 0 or the maximum.
	health = clamp(newHealth, 0, maxHealth)
	healthbar.value = health
	Logger.info("Player now has %s health." % health)
	if (healthbar.value <= 0):
		death()

## Currently "kills" the player by respawning them immediately.
func death():
	Logger.info("Player died.")
	respawn()

## Currently "respawns" the player by setting their health to max and resetting their position.
func respawn():
	Logger.info("Player respawned.")
	position = Vector3(0, 0, 3)
	set_health(100)
	
## Players interact function. If an interactive object is found, it will be
## sent to that object's interact function. See [method item.interact]
func interact():
	wictl.interact()

func add_item(item: ItemWrapper):
	if wictl.inventory.add(item):
		inventory_control.update(wictl.inventory.items)

var pos_updated: bool = false
func _physics_process(delta):
	# This function will be called on each client for all player instances.
	# This means that in a game with 4 players, each client will have this function
	# called for all 4 players, but we do not want the player to control all 4
	# players so we return early here.
	if not _client_is_player:
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		
		if updating_rotation:
			var y_diff = target_rotation.y - rotation.y
			if y_diff > PI:
				y_diff -= 2 * PI
			elif y_diff < -PI:
				y_diff += 2 * PI
			
			var x_diff = target_rotation.x - camera.rotation.x
			if x_diff > PI:
				x_diff -= 2 * PI
			elif x_diff < -PI:
				x_diff += 2 * PI
				
			rotate_y(y_diff / 16 + 0.005)
			camera.rotate_x(x_diff / 16 + 0.005)
			if rotation.y == target_rotation.y and camera.rotation.x == target_rotation.x:
				updating_rotation = false
		return
	
	var old_vel = velocity
	var changed_vel = false
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		changed_vel = true
		Logger.trace("Player (%s) jumped with vel. y: %f" % [name, JUMP_VELOCITY])
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		Logger.trace("Moving Player %s with vel. x: %f z: %f" % [name, velocity.x, velocity.z])
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	move_and_slide()
		
	counter += 1
	if counter - 16 == 0:
		Logger.info("Step")
		counter = 0
		if updating_rotation:
			last_updated_rotation = Vector2(camera.rotation.x, rotation.y)
			_client_update_rotation.rpc(camera.rotation.x, rotation.y)
			updating_rotation = false
		if not pos_updated:
			Logger.info("Updating pos")
			pos_updated = true
			_server_update_pos.rpc(position)
			return
	
	if changed_vel or old_vel.x != velocity.x or old_vel.z != velocity.z:
		pos_updated = false 
		_server_update_vel.rpc(velocity)
	

@rpc("unreliable", "any_peer")
func _server_update_vel(vel: Vector3):
	_update_vel.rpc(vel)

@rpc("unreliable", "any_peer")
func _server_update_pos(pos: Vector3):
	_update_pos.rpc(pos)

@rpc("call_local", "unreliable", "authority")
func _update_vel(vel: Vector3):
	Logger.info("%s Movnig %s with vel %s" % [multiplayer.get_unique_id(), client_id, vel])
	velocity = vel
	move_and_slide()

@rpc("call_local", "unreliable", "authority")
func _update_pos(pos: Vector3):
	position = pos
