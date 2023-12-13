extends VBoxContainer
class_name Category
## NOTICE this requires set_player to initialize properly

@onready var grid_container = $GridContainer
@onready var rich_text_label = $CategoryLabel/RichTextLabel
const SLOT = preload("res://player/inventory/GUI/Slot.tscn")

var items: Array[ItemWrapper]
var player: Player
var label: String

## There is potential for an error if [method _ready] gets called before 
## [method set_category]
func set_player(player: Player) -> void:
	self.player = player

func add(item: ItemWrapper):
	if self:
		var slot = SLOT.instantiate()
		slot.set_item(player, item)
		grid_container.add_child(slot)
	else:
		Logger.debug("Category.add: Defer item add to _ready")
		items.append(item)

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
		slot.set_item(player, item)
		
		Logger.debug("category on ready: adding %s" % slot)
		grid_container.add_child(slot)
