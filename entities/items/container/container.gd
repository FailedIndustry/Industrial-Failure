extends NetworkedItem
class_name ContainerItem

var inventory: Inventory = Inventory.new()
var inventory_control: ContainerGUICtrl

func _ready():
	inventory.items = server_global.generate_test_inv(self)
	server_interact = server_function
	client_interact = open_container

##### General #####

func _container_raycast(player: Player, container_id: int):
	var hitscan_results = globals.interact_raycast(player)
	if not hitscan_results: return -1
	for child in hitscan_results["collider"].get_children():
		if child is ContainerItem:
			return child

func server_function(player: Player):
	pass

##### Get Inventory / Open Container ######
const CONTAINER_INVENTORY_GUI = preload("res://inventory/GUI/container/ContainerInventoryGUI.tscn")
func open_container(player: Player):
	Logger.debug("open_container")
	_server_get_inventory.rpc_id(1)
	await container_inventory_update
	Logger.debug("open_container2")
	var gui: ContainterContainer = CONTAINER_INVENTORY_GUI.instantiate()
	gui.create(player, self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.ui.show()
	for child in player.ui.get_children():
		child.hide()
	player.ui.add_child(gui)
	inventory_control = gui.container_control

@rpc("any_peer", "reliable", "call_remote")
func _server_get_inventory():
	Logger.debug("_server_get_inventory")
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = server_global.get_player_by_id(peer_id)
	var ids: PackedInt32Array
	var type_ids: PackedInt32Array
	var quantities: PackedInt32Array
	for item in inventory.items:
		ids.append(item.id)
		type_ids.append(item.item_type.id)
		quantities.append(item.quantity)
	
	_client_get_container_inventory.rpc(ids, type_ids, quantities)

signal container_inventory_update
@rpc("any_peer")
func _client_get_container_inventory(ids: PackedInt32Array, type_ids: PackedInt32Array, quantities: PackedInt32Array):
	Logger.debug("_client_get_container_inventory")
	inventory.items.clear()
	for i in ids.size():
		var item: ItemWrapper = ItemWrapper.new()
		item.id = ids[i]
		item.item_type = server_global.item_types[type_ids[i]]
		item.quantity = quantities[i]
		item.owner = self
		Logger.info("%s" % item)
		inventory.add(item)
	
	container_inventory_update.emit()

##### Take From Player #####
signal _tfp_res(int)

func take_from_player(item: ItemWrapper):
	_server_take_from_player.rpc_id(1, item.item_type.id, item.quantity)
	return _tfp_res

@rpc("any_peer", "call_remote", "reliable")
func _server_take_from_player(type_id: int, quantity: int):
	var client_id = multiplayer.get_remote_sender_id()
	var player: Player = server_global.get_player_by_id(client_id)
	var item_type = server_global.item_types[type_id]
	
	var removed_item: ItemWrapper = player.wictl.inventory.remove(item_type, quantity)
	if not removed_item:
		_client_take_from_player.rpc_id(client_id, -1)
		return
	
	removed_item.owner = self
	inventory.add(removed_item)
	_client_take_from_player.rpc_id(client_id, 0)

@rpc("authority", "call_remote", "reliable")
func _client_take_from_player(res: int):
	_tfp_res.emit(res)

##### Take From Container #####
signal _tfc_res(int)

func take_from_container(player: Player, item: ItemWrapper):
	_server_take_from_container.rpc_id(1, item.id, item.item_type.id, item.quantity)
	return _tfc_res

@rpc("any_peer", "call_remote", "reliable")
func _server_take_from_container(container_id: int, 
								 type_id: int, quantity: int):
	var client_id = multiplayer.get_remote_sender_id()
	var player = server_global.get_player_by_id(client_id)
	if _container_raycast(player, container_id) != self:
		_client_take_from_container.rpc_id(client_id, -1)
		return
	
	var item_type = server_global.item_types[type_id]
	var removed_item: ItemWrapper = inventory.remove(item_type, quantity)
	if not removed_item:
		_client_take_from_container.rpc_id(client_id, -1)
		return
	
	removed_item.owner = player
	player.wictl.inventory.add(removed_item)
	_client_take_from_container.rpc_id(client_id, 0)

@rpc("authority", "reliable")
func _client_take_from_container(res: int):
	_tfc_res.emit(res)
