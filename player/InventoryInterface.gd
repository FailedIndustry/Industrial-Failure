extends Control
@onready var inventory_panel = $InventoryPanel
@onready var grabbed_slot_panel = $GrabbedSlotPanel
@onready var player = $"../.."
var inventory: InventoryData
var grabbed_index: int = -1

func _ready():
	inventory = player.inventory_data

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
	
	match [grabbed_index, button]:
		[-1, MOUSE_BUTTON_LEFT]:
			grabbed_index = index
		[_, MOUSE_BUTTON_LEFT]:
			grabbed_index = inventory_data.drop_slot_data(grabbed_index, index)
		[_, MOUSE_BUTTON_RIGHT]:
			grabbed_index = inventory_data.drop_single_slot_data(grabbed_index, index)
	
	Logger.info("%s" % grabbed_index)
	update_grabbed_slot()
	

func update_grabbed_slot() -> void:
	if grabbed_index == -1:
		grabbed_slot_panel.hide()
		return
	
	var grabbed_slot_data = inventory.slot_datas[grabbed_index]
	if grabbed_slot_data:
		grabbed_slot_panel.show()
		grabbed_slot_panel.set_slot_data(grabbed_slot_data)
	else:
		grabbed_slot_panel.hide()
