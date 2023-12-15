extends VBoxContainer
class_name Category
## NOTICE this requires inv_owner and label to be set to initialize properly

@onready var grid_container = $GridContainer
@onready var rich_text_label = $CategoryLabel/RichTextLabel
const SLOT = preload("res://player/inventory/GUI/Slot.tscn")

var items: Array[ItemWrapper]
## The owner of the category/inventory this represents.
var inv_owner
## The authoritative string on what category this is and what is displayed
## in the category label in the GUI
var label: String

## There is potential for an error if [method _ready] gets called before 
## [method set_category]
func set_player(player: Player) -> void:
	self.player = player

func add(item: ItemWrapper):
	if self:
		var slot = SLOT.instantiate()
		slot.set_item(inv_owner, item)
		grid_container.add_child(slot)
	else:
		Logger.debug("Category.add: Defer item add to _ready")
		items.append(item)

## Sets the category label
func set_label(category: String):
	if rich_text_label:
		label = category
		rich_text_label.text = label
	else:
		label = category

## There is potential for an error if [method _ready] gets called before 
## [method set_category]
func _ready() -> void:
	set_label(label)
	for item in items:
		var slot = SLOT.instantiate()
		slot.set_item(inv_owner, item)
		
		Logger.debug("category on ready: adding %s" % slot)
		grid_container.add_child(slot)
