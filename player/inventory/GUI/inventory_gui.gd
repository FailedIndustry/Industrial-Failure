extends PanelContainer
class_name Inventory_GUI
## NOTICE this requires set_player to initialize properly

const CATEGORY = preload("res://player/inventory/GUI/Category.tscn")
@onready var v_box_container = $ColorRect/VBoxContainer
@onready var grabbed_visual = $GrabbedSlot
var grabbed_slot: Slot
var player: Player

@export var items: Array[ItemWrapper]

func set_player(player: Player) -> void:
	self.player = player

func update(items: Array[ItemWrapper]) -> void:
	Logger.info("Creating inventory for %s" % self)
	for child in v_box_container.get_children():
		if child is PanelContainer: continue
		child.queue_free()
	
	var categories: Array[String]
	for i in items:
		var category = get_or_make_category(i.item_type.category)
		Logger.debug("Adding %s to %s" % [i.item_type.name, category.label])
		category.add(i)

func get_or_make_category(category: String) -> VBoxContainer:
	var categories = v_box_container.get_children()
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
	new_category.set_player(player)
	v_box_container.add_child(new_category)
	return new_category

## Returns 0 for success or -1 for error
func delete_or_reduce_item(item: ItemWrapper) -> int:
	for category in v_box_container.get_children():
		if category is PanelContainer: continue
		
		if category.label == item.item_type.category:
			for slot: Slot in category.grid_container.get_children():
				if slot.item.item_type == item.item_type:
					if slot.item.quantity > item.quantity:
						slot.item.quantity -= item.quantity
						return 0
					elif slot.item.quantity == item.quantity:
						slot.queue_free()
					else:
						Logger.error("inventory_gui.delete_or_reduce_item: quantity mistmatch")
						return -1
		
	# if no matches were found, return an error
	Logger.error("Attempted to remove an item from inventory that is no longer there")
	return -1

func grab_item(slot: Slot):
	if slot.is_grabbed:
		pass
	else:
		Logger.debug("Grabbed %s" % slot.item.item_type.name)
		grabbed_visual.set_item(slot.item)
		grabbed_visual.show()
		grabbed_slot = slot

func swap_item(slot: Slot):
	if grabbed_slot \
			and grabbed_slot.item.item_type.category == slot.item.item_type.category:
		Logger.debug("Swapping %s and %s" % [slot.item.item_type.name, grabbed_slot.item.item_type.name])
		var temp_item = grabbed_slot.item
		grabbed_slot.item = slot.item
		slot.item = temp_item
		slot.render()
		grabbed_slot.render()
		grabbed_slot = null
		grabbed_visual.hide()

func press_on_item(slot: Slot, button_index: int):
	match button_index:
		MOUSE_BUTTON_LEFT:
			if grabbed_slot \
					and grabbed_slot.item.item_type.category == slot.item.item_type.category:
				swap_item(slot)
			else:
				grab_item(slot)
		MOUSE_BUTTON_RIGHT:
			player.drop_item(slot.item)

func _on_gui_input(event):
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT) \
				or (event.button_index == MOUSE_BUTTON_RIGHT) \
				and event.is_pressed():
			Logger.debug("InventoryInterface: button click")
			grabbed_visual.hide()
			if grabbed_slot:
				grabbed_slot = null

func _physics_process(_delta):
	if grabbed_slot and grabbed_visual:
		grabbed_visual.global_position = get_global_mouse_position() + Vector2(10,10)
