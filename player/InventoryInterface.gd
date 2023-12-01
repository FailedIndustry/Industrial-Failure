extends Control
@onready var inventory_panel = $InventoryPanel
@onready var grabbed_slot_panel = $GrabbedSlotPanel

var grabbed_slot_data: SlotData

func _physics_process(delta):
	if grabbed_slot_panel.visible:
		# If vector is not offset, then GrabbedSlotPanel will be what is captured
		# in mouse events, so placing it in another slot in the inventory or placing
		# it on the ground won't work unless this is patched. Also tooltip will
		# show up
		grabbed_slot_panel.global_position = get_global_mouse_position() + Vector2(5,5)

func set_player_inventory(inventory_data: InventoryData): 
	inventory_data.inventory_interact.connect(on_inventory_interact)
	inventory_panel.populate(inventory_data)

func on_inventory_interact(
	inventory_data: InventoryData,
	index: int,
	button: int,
) -> void:
	Logger.debug("InventoryInterface: %s clicked with button %s" % [index, button])
	
	match [grabbed_slot_data, button]:
		[null, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.grab_slot_data(index)
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)
	
	Logger.info("%s" % grabbed_slot_data)
	update_grabbed_slot()
	

func update_grabbed_slot() -> void:
	if grabbed_slot_data:
		grabbed_slot_panel.show()
		grabbed_slot_panel.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot_panel.hide()
