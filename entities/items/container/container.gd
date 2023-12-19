extends NetworkedItem
class_name ContainerItem

var inventory: Array[ItemWrapper]

func _ready():
	inventory = server_global.generate_test_inv()
	server_interact = server_function
	client_interact = open_container

func get_inventory(player: Player):
	Logger.debug("get_inventory")
	_server_get_inventory()

@rpc("any_peer", "reliable", "call_remote")
func _server_get_inventory():
	Logger.debug("_server_get_inventory")
	var peer_id: int = multiplayer.get_remote_sender_id()
	var player: Player = server_global.get_player_by_id(peer_id)
	var ids: PackedInt32Array
	var type_ids: PackedInt32Array
	var quantities: PackedInt32Array
	for item in inventory:
		ids.append(item.id)
		type_ids.append(item.item_type.id)
		quantities.append(item.quantity)
	
	_client_get_container_inventory.rpc(ids, type_ids, quantities)

signal container_inventory_update
@rpc("any_peer")
func _client_get_container_inventory(ids: PackedInt32Array, type_ids: PackedInt32Array, quantities: PackedInt32Array):
	Logger.debug("_client_get_container_inventory")
	inventory.clear()
	for i in ids.size():
		var item: ItemWrapper = ItemWrapper.new()
		item.id = ids[i]
		item.item_type = server_global.item_types[type_ids[i]]
		item.quantity = quantities[i]
		item.owner = self
		inventory.append(item)
	
	container_inventory_update.emit()

const CONTAINER_INVENTORY_GUI = preload("res://inventory/GUI/container/ContainerInventoryGUI.tscn")
func open_container(player: Player):
	Logger.debug("open_container")
	_server_get_inventory.rpc_id(1)
	await container_inventory_update
	Logger.debug("open_container2")
	var gui: ContainterContainer = CONTAINER_INVENTORY_GUI.instantiate()
	gui.create(player, self)
	player.add_child(gui)

func server_function(player: Player):
	pass

func take_from_player(player: Player, item: ItemWrapper):
	pass

## Add moved item to player and remove from container
@rpc("authority", "reliable")
func add_item_to_player(player: Player) -> void:
	item_data.owner = player
	player.wictl.inventory.add(item_data)
