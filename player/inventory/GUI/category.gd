extends VBoxContainer
@onready var grid_container = $GridContainer
const SLOT = preload("res://player/inventory/GUI/Slot.tscn")

var items: Array[ItemData]
var gui: Inventory_GUI

## There is potential for an error if [method _ready] gets called before 
## [method set_category]
func set_category(gui: Inventory_GUI, items: Array[ItemData]) -> void:
	for i in items:
		Logger.info("set_category: adding %s" % i)
	self.items = items
	self.gui = gui

## There is potential for an error if [method _ready] gets called before 
## [method set_category]
func _ready() -> void:
	var counter: int = 0;
	for item in items:
		var slot = SLOT.instantiate()
		slot.set_item(gui, item, counter)
		counter += 1
		
		Logger.debug("category on ready: adding %s" % slot)
		grid_container.add_child(slot)
