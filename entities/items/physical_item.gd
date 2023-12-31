extends NetworkedItem
class_name Pickup

func _ready():
	server_interact = server_function
	client_interact = update_wrapper

## [method NetworkedItem.client_interact] needs a function, but we just want it to send straight
## to the server. So we will just wrap the [method NetworkedItem.server_update_state] function
func update_wrapper(player: Player):
	Logger.debug("ID: %d - C" % multiplayer.get_unique_id())
	server_update_state.rpc_id(0)

## As seen in [method _ready], this is what will be called on the server. We will replicate
## the inventory to the player that this was called on, but no others. We will delete the object
## on all players via [method update].
func server_function(player: Player):
	Logger.debug("ID: %d -S" % multiplayer.get_unique_id())
	add_item_to_player(player)
	add_item_to_player.rpc_id(player.client_id, player)
	update.rpc()

## We need to send the client the item on our side because they may not have current state
## of the item
@rpc(
	"authority",
	"reliable"
)
func add_item_to_player(player: Player) -> void:
	Logger.debug("ID: %d -C" % multiplayer.get_unique_id())
	Logger.debug("Pickupable.add_item_to_player: Adding item to player")
	item_data.owner = player
	player.wictl.inventory.add(item_data)

## Delete object from all connected players. This is sent to all players in 
## [method add_item_to_player]
@rpc("authority",	# Only accept rpc calls from the server
 	"call_local",	# Update the server too
 	"reliable")		# Make sure all clients get this call
func update():
	Logger.debug("ID: %d" % multiplayer.get_unique_id())
	Logger.debug("Pickupable.update: Removing item")
	get_parent().queue_free()
