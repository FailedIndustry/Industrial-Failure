extends PanelContainer
class_name Inventory_GUI

const CATEGORY = preload("res://player/inventory/GUI/Category.tscn")
const SLOT_MENU = preload("res://player/inventory/GUI/SlotMenu.tscn")
@onready var v_box_container = $ColorRect/VBoxContainer
@onready var grabbed_visual = $GrabbedSlot
var grabbed_slot: Slot

@export var items: Array[ItemWrapper]

var inventory_owner: Player

func create(inventory_owner: Player) -> void:
	Logger.info("Creating inventory for %s" % self)
	var category = CATEGORY.instantiate()
	for i in items:
		Logger.debug("inventory.create: adding %s" % i)
	category.set_category(self, items)
	
	v_box_container.add_child(category)

func grab_item(slot: Slot):
	if slot.is_grabbed:
		pass
	else:
		Logger.debug("Grabbed %s" % slot.item.item_type.name)
		grabbed_visual.set_item(slot.item)
		grabbed_visual.show()
		grabbed_slot = slot

func swap_item(slot: Slot):
	if grabbed_slot:
		Logger.debug("Swapping %s and %s" % [slot.item.item_type.name, grabbed_slot.item.item_type.name])
		var temp_item = grabbed_slot.item
		var temp_index = grabbed_slot.index
		grabbed_slot.item = slot.item
		grabbed_slot.index = slot.index
		slot.item = temp_item
		slot.index = temp_index
		slot.render()
		grabbed_slot.render()
		grabbed_slot = null
		grabbed_visual.hide()

func press_on_item(slot: Slot):
	if grabbed_slot:
		swap_item(slot)
	else:
		grab_item(slot)
		
func show_item_menu(slot: Slot):
	Logger.info("Creating item slot menu")
	var slotMenu = SLOT_MENU.instantiate()
	add_child(slotMenu)

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
