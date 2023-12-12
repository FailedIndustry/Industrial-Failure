extends PanelContainer
class_name Slot

@onready var quantity_label = $QuantityLabel
@onready var texture_rect = $MarginContainer/TextureRect

var item: ItemWrapper
## The item owner when set_item was called
var is_grabbed: bool = false
var player: Player

## [param item] is the ItemData from which to draw quantity and texture.
## 
## There is potential for an error if [method _ready] gets called before 
## [method set_item]
func set_item(player: Player, item: ItemWrapper):
	self.item = item
	self.player = player
	if texture_rect and quantity_label:
		render()
	else:
		# Then it will be rendered in [method _ready]
		pass

func render():
	if player != item.owner:
		Logger.error("mismatch in owners during inventory render")
		# self.hide()
		# return 
	texture_rect.texture = item.item_type.texture
	tooltip_text = "%s\n%s" % [item.item_type.name, item.item_type.description]

	if item.quantity > 1:
		quantity_label.text = "%s" % item.quantity
		quantity_label.show()
	else:
		quantity_label.hide()

## There is potential for an error if [method _ready] gets called before 
## [method set_item]
func _ready():
	render()

func _on_gui_input(event):
	if item.owner != player:
		Logger.error("Mismatch in owners during GUI event")
		# self.hide()
		# return
	
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT \
				or event.button_index == MOUSE_BUTTON_RIGHT) \
				and event.is_pressed():
			player.inventory_gui.press_on_item(self)
