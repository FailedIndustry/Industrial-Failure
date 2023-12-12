extends PanelContainer

@onready var quantity_label = $QuantityLabel
@onready var texture_rect = $MarginContainer/TextureRect

func set_item(item: ItemData):
	texture_rect.texture = item.texture

	if item.quantity > 1:
		quantity_label.text = "%s" % item.quantity
		quantity_label.show()
	elif item.quantity <= 0:
		Logger.error("Item quantity is less than 0!")
	else:
		quantity_label.hide()
