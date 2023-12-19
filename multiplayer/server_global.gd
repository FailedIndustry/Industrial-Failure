extends Node

var players: Array[Player]
var item_types: Array[ItemType]
var counter: int = 0

const ITEM_1 = preload("res://entities/items/Item1.tres")
const ITEM_2 = preload("res://entities/items/Item2.tres")
const ITEM_3 = preload("res://entities/items/Item3.tres")

func get_item_type_id(type: ItemType) -> int:
	if item_types.is_empty(): initialize()
	for i in item_types.size():
		if item_types[i] == type:
			return i
	
	return -1

func get_player_by_id(id: int):
	if item_types.is_empty(): initialize()
	for player in players:
		if player.client_id == id:
			return player

func add_item_type(type: ItemType) -> int:
	type.id = item_types.size()
	item_types.append(type)
	return type.id

func initialize():
	add_item_type(ITEM_1)
	add_item_type(ITEM_2)
	add_item_type(ITEM_3)

func create_item(type: ItemType, quantity: int) -> ItemWrapper:
	if item_types.is_empty(): initialize()
	var item = ItemWrapper.new()
	item.item_type = type
	item.quantity = quantity
	item.id = counter
	counter += 1
	return item

func generate_test_inv() -> Array[ItemWrapper]:
	if item_types.is_empty(): initialize()
	var arr: Array[ItemWrapper]
	for type in item_types:
		var item = create_item(type, type.id)
		arr.append(item)
	
	return arr
