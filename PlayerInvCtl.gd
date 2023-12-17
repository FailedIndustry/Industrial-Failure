extends Node
class_name WICtl
## World Interface Control. This is the interaction point for the Player class to interact with
## world state.
##
## Unlike Player class that has no RPCs, WICtl is inherantly networked and handles networking
## functions for the player.

@export var inventory: Inventory
@export var INTERACTION_DISTANCE = 2

var player: Player

func _ready():
	var parent = get_parent()
	if parent is Player:
		player = parent
	else:
		Logger.error("WICtl: parent node must be player, but found %s" % parent)

func drop_item(item: ItemWrapper):
	if inventory.drop(item) == 0:
		item.owner = get_node("/root/Main/Game")

func interact():
	var globals: Globals = get_node("/root/Globals")
	var result = globals.interact_raycast(player)
	if result.is_empty():
		Logger.debug("WICtl.interact: No item found in raycast")
		return
	
	var collider: Object = result["collider"]
	Logger.debug("WICtl.interact: raycast hit %s" % collider.name)
	for child in collider.get_children():
		if child is NetworkedItem and child.has_method("interact"):
			Logger.debug("WICtl.interact: child %s is NetworkedItem. Calling interact" % child.name)
			child.interact(player)
			return
	
	Logger.debug("WICtl.interact: No NetworkedItem found.")
