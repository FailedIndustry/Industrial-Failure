extends Node
class_name NetworkedItem

@export var item_data: ItemWrapper

@onready var globals: Globals = get_node("/root/Globals")

## Function run on server after verifying raycast and in [method server_update_state]. Updating 
## client must be done in this function too. This has the signature of (Player) -> void.
##
## It is suggested to use the following rpc arguments when updating the client:
## @rpc("authority",	# Only accept rpc calls from the server
##	 	"call_remote",	# Do not update server. Change to call_local if this should be run 
##						  on the server too
##	 	"reliable"		# Make sure all clients get this call
## When calling the rpc you created, make sure to use <function>.rpc() to update all clients
var server_interact: Callable

## Function run on the client when interaction function is run. This is inteneded to call
## [method server_update_state].rpc(0) at the appropriate time. Function signature is 
## (Player) -> void.
##
## [method interact] is a wrapper around this to provide type-safe interface to this call.
## Players will search for NetworkedItem when local interaction function is run, then call
## [method interact] and pass in themself (which will in turn call this callable).
##
## Use [method server_update_state].rpc(0) to make sure that the call is sent to the server.
var client_interact: Callable
@onready var server_global: ServerGlobal = get_node("/root/ServerGlobal")

## Interact entry point for each local item. This will be sent to the server
## in another function.
## 
## This function is present on every client (and host) mirror of an item and
## is merely a wrapper around [method server_update_state]. Use this function
## to identify if an item is interactable and then call the interaction through
## this method. See [method player.interact] for an example.
func interact(player: Player):
	Logger.debug("ID: %d" % multiplayer.get_unique_id())
	Logger.debug("NetworkedItem.interact: peer_id %d interacted with item" \
				% multiplayer.get_unique_id())
	
	client_interact.call(player)

## Call the server to update the state of the item. The server will verify
## this request and then send it to all clients.
@rpc("any_peer", 	# Any client can request and update in state
	 "call_local",	# Make sure client updates their local state too
	 "reliable"		# Make sure the server gets the request
) func server_update_state():
	Logger.debug("ID: %d" % multiplayer.get_unique_id())
	var sender_id = multiplayer.get_remote_sender_id()
	Logger.debug("NetworkedItem.server_update_state: peer_id %d interacted with item" \
				% sender_id)
	
	var matches: Array[Player] = server_global.players.filter(
		func(p): 
			Logger.debug("Found %d" % p.client_id)
			return p.client_id == sender_id)
	
	if matches.size() != 1:
		Logger.error("NetworkedItem.server_update_state: There are %d peer_id %d" \
					% [matches.size(), sender_id])
		return
	else: 
		var player = matches[0]
		var result = globals.interact_raycast(player)
		if not result: return -1
		var collider: Object = result["collider"]
		if collider.get_instance_id() == get_parent().get_instance_id():
			server_interact.call(player)
		else:
			Logger.debug("NetworkedItem.server_update_state: mismatch in collision object IDs")
