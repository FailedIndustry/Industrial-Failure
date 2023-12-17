extends PanelContainer
class_name InventoryGUI
## The acutal GUI panel of [Inventory]. This does contain any persistant state or any authority
## on inventory items (see [Player] for that). Nor does this handle input (see [InventoryControl]
## for that)
##
## [Player] is the ultimate authority on their inventory, and [InventoryControl] handles 
## modifications and actions on the inventory. For instance, this 

const CATEGORY = preload("res://player/inventory/GUI/Category.tscn")
## A virtical box container for categories.
@onready var category_container = $Background/CategoryContainer

## The owner of the inventory. Drop and/or add will be called on the owner.
var inv_owner

func update(items: Array[ItemWrapper]) -> void:
	Logger.info("Creating inventory for %s" % self)
	for child in category_container.get_children():
		if child is PanelContainer: continue
		child.queue_free()
	
	for i in items:
		var category: Category = get_or_make_category(i.item_type.category)
		Logger.debug("Adding %s to %s" % [i.item_type.name, category.label])
		category.add(i)

func get_or_make_category(category: String) -> VBoxContainer:
	var categories = category_container.get_children()
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
	category_container.add_child(new_category)
	return new_category

## If exact quantity match, delete the item. If < quantity in inventory, reduce. If there is inavlid
## input, this will return -1, otherwise 0. This will also update the GUI.
func delete_or_reduce(item: ItemWrapper) -> int:
	for category in category_container.get_children():
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

## On input to the inventory GUI panel
func _on_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
			inv_owner.inventory_control._inventory_gui_clicked(self, event.button_index)
