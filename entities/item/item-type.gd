extends Resource
class_name ItemType
## A type of item, like an apple. Unlike [ItemWrapper], this does not contain
## any information that should change at runtime

@export var name: String = "Error: Name not set"
@export_multiline var description: String = "Error: Description not set"
@export var stackable: bool = false
@export var category: String = "Error: Category not set"
## Texture of the item in the inventory
@export var texture: Texture
## Physical representation of the item
@export var physical_item: PackedScene = preload("res://entities/items/PhysicalItem.tscn")
## action[0] is the array of Callable functions, action[1] is the array of names
## The actions a player can take on an item when right clicked in inventory.
## It is always assumed that the player is able to take an aciton
@export var actions: Array[Array]

@export var id: int = -1
