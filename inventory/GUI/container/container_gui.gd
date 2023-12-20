extends PanelContainer
class_name CategoryGUI
## The acutal GUI panel of [Inventory]. This does contain any persistant state or any authority
## on inventory items (see [Player] for that). Nor does this handle input (see [InventoryControl]
## for that)
##
## [Player] is the ultimate authority on their inventory, and [InventoryControl] handles 
## modifications and actions on the inventory. For instance, this 

const CATEGORY = preload("res://inventory/GUI/Category.tscn")
@onready var pl_cat_container = $Player/Background/CategoryContainer
@onready var ex_cat_container = $External/Background/CategoryContainer

## The owner of the inventory. Drop and/or add will be called on the owner.
var player: Player
var external: ContainerItem

func update(inv_owner: Object, pl_items: Array[ItemWrapper], ex_items: Array[ItemWrapper]) -> void:
	_update_container(inv_owner, pl_items, pl_cat_container)
	_update_container(inv_owner, ex_items, ex_cat_container)

func _update_container(inv_owner: Object, items: Array[ItemWrapper], cat_container: VBoxContainer) -> void:
	for child in cat_container.get_children():
		if child is PanelContainer: continue
		child.queue_free()
	
	for i in items:
		var category: Category = _get_or_make_category(inv_owner, i.item_type.category, cat_container)
		Logger.debug("Adding %s to %s" % [i.item_type.name, category.label])
		category.add(i)

func _get_or_make_category(inv_owner: Object, category: String, cat_container: VBoxContainer) -> VBoxContainer:
	var categories = cat_container.get_children()
	for c in categories:
		if c is PanelContainer: continue
		# [method update] frees children, but will not delete them by the time
		# this is called.
		if c.label == category and not c.is_queued_for_deletion():
			return c
	
	# if there are no categories or no categories match
	Logger.debug("adding new category %s" % category)
	var new_category = CATEGORY.instantiate()
	new_category.set_label(category)
	new_category.inv_owner = inv_owner
	cat_container.add_child(new_category)
	return new_category

## If exact quantity match, delete the item. If < quantity in inventory, reduce. If there is inavlid
## input, this will return -1, otherwise 0. This will also update the GUI.
func delete_or_reduce(item: ItemWrapper, cat_container: VBoxContainer) -> int:
	for category in cat_container.get_children():
		if category is PanelContainer: continue
		
		if category.label == item.item_type.category:
			for slot: Slot in category.grid_container.get_children():
				if slot.item.item_type == item.item_type:
					if slot.item.quantity > item.quantity:
						Logger.debug("inventory_gui.delete_or_reduce: reducing %s by %d"
									% [slot.item.item_type.name, slot.item.quantity])
						slot.item.quantity -= item.quantity
						return 0
					elif slot.item.quantity == item.quantity:
						Logger.debug("inventory_gui.delete_or_reduce: removing %s"
									% slot.item.item_type.name)
						slot.queue_free()
						return 0
					else:
						Logger.error("inventory_gui.delete_or_reduce: quantity mistmatch")
						return -1
		
	# if no matches were found, return an error
	Logger.error("Attempted to remove an item from inventory that is no longer there")
	return -1

## Swaps two slots in-place by swapping [member Slot.item] and calling [method Slot.render]
func swap_slots(a: Slot, b: Slot):
	var temp_item = a.item
	a.item = b.item
	b.item = temp_item
	a.render()
	b.render()
