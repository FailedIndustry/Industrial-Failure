extends PanelContainer

@onready var quantity_label = $QuantityLabel
@onready var texture_rect = $MarginContainer/TextureRect

func set_item(item: ItemWrapper) -> int:
	if item.quantity <= 0:
		Logger.error("Item quantity is less than 0!")
		unset_item()
		return -1

	if item.quantity > 1:
		quantity_label.text = "%s" % item.quantity
		quantity_label.show()
	else:
		quantity_label.hide()
	
	texture_rect.texture = item.item_type.texture
	show()
	z_index = 1000
	return 0

func unset_item():
	# This should be changed to an error texture
	texture_rect.texture = null
	quantity_label.text = "Error: GrabbedSlot does not have an item"
	hide()
