extends PanelContainer
class_name Slot
## A slot in a [Category]. Consumes mouse input on slots and sends it to [InventoryCtrl]
##
## [InventoryGUICtrl] controls [InventoryGUI]. [InventoryGUI] displays it's items in [Category]s
## [Category]s displays it's items in [Slot]s.

@onready var quantity_label = $QuantityLabel
@onready var texture_rect = $MarginContainer/TextureRect

var item: ItemWrapper
## The item owner when set_item was called
var is_grabbed: bool = false
var item_owner

## [param item] is the ItemData from which to draw quantity and texture.
## 
## There is potential for an error if [method _ready] gets called before 
## [method set_item]
func set_item(_item_owner: Object, _item: ItemWrapper):
	self.item = _item
	self.item_owner = _item_owner
	if texture_rect and quantity_label:
		render()
	else:
		# Then it will be rendered in [method _ready]
		pass

func render():
	if item_owner != item.owner:
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
	if item.owner != item_owner:
		Logger.error("Mismatch in owners during GUI event")
		# self.hide()
		# return
	
	if event is InputEventMouseButton and event.is_pressed():
		item_owner.inventory_control._slot_clicked(self, event.button_index)
