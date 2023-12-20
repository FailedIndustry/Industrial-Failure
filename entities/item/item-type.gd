extends Resource
class_name ItemType
## A type of item, like an apple. Unlike [ItemWrapper], this does not contain
## any information that should change at runtime

@export var name: String = ""
@export_multiline var description: String = ""
@export var stackable: bool = false
@export var category: String
## Texture of the item in the inventory
@export var texture: Texture
## Physical representation of the item
@export var physical_item: PackedScene = preload("res://entities/items/PhysicalItem.tscn")

@export var id: int
