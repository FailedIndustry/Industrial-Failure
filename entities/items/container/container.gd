extends NetworkedItem
class_name ContainerItem

var inventory: Array[ItemWrapper]

func _ready():
	server_interact = server_function
	client_interact = open_container

func open_container(player: Player):
	player.ui

## Get the container items
func server_function(player: Player):
	pass

## Add moved item to player and remove from container
@rpc("authority", "reliable")
func add_item_to_player(player: Player) -> void:
	item_data.owner = player
	player.wictl.inventory.add(item_data)
