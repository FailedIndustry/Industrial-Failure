extends Control
@onready var inventory_panel = $InventoryPanel

func set_player_inventory(inventory_data: InventoryData):
	inventory_panel.populate(inventory_data.slot_datas)
