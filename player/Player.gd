extends CharacterBody3D
class_name Player

@onready var server_global: ServerGlobal = get_node("/root/ServerGlobal")
@onready var healthbar: TextureProgressBar = $Healthbar
@onready var inventory_control: InventoryGUICtrl = $UI/InventoryControl
@onready var inventory_gui: InventoryGUI = $UI/InventoryGUI
@onready var camera: Camera3D 	= $Camera3D
@onready var wictl: WICtl 		= $WICtl
@onready var mrctl: MRCtl 		= $MRCtl
@onready var ui: CanvasLayer 	= $UI

@export var SPEED 			= 5.0
@export var JUMP_VELOCITY 	= 3
@export var MOUSE_SPEED		= 0.0015
@export var maxHealth: int 	= 100

var client_id: int
var health: int = maxHealth : set = set_health 
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
	
	server_global.local_player = self
	server_global.client_id = client_id
	Logger.debug("_ready: Local is authority for %s, capturing mouse and setting \
				  current camera" % name)
	
	inventory_control.update(wictl.inventory.items)
	inventory_control.player = self
	inventory_gui.inv_owner = self
	wictl.inventory.owner = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	healthbar.value = health
	wictl.inventory.items = server_global.generate_test_inv(self)

func _unhandled_input(event):
	if not _client_is_player: return
	
	if event is InputEventMouseMotion:
		mrctl.update_rotation(event)
	elif event.is_action_pressed("interact") and not event.is_echo():
		# TEST for damage system
		# damage(10)
		Logger.debug("_unhandled_input: Player pressed interact button")
		interact()
	elif event.is_action_pressed("open_inventory") and not event.is_echo():
		if ui.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			for child in ui.get_children():
				child.hide()
			ui.hide()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			var viewport = DisplayServer.window_get_size()
			for child in ui.get_children():
				child.hide()
			ui.show()
			inventory_control.update(wictl.inventory.items)
			inventory_gui.position = Vector2(viewport.x/2, viewport.y/2)
			inventory_control.show()
			inventory_gui.show()
	# TEST for heal system. Jump is handled in [method _physics_process]
	elif event.is_action_pressed("jump"):
		heal(10)

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

func _physics_process(delta):
	if _client_is_player:
		mrctl.local_move(delta)
	else:
		mrctl.remote_move(delta)

