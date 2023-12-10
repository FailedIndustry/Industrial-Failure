extends Resource

class_name ItemData
@export var name: String = ""
@export_multiline var description: String = ""
@export var stackable: bool = false
@export var texture: Texture

## This needs to be abstracted out
@export var quantity: int = 1

## This should be changed to owner_id or something like that
var owner: Object
