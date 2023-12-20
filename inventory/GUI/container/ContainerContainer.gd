extends Node2D
class_name ContainterContainer
## The Container for Container Control and the GUIs attached.
@onready var container_control: ContainerGUICtrl = $ContainerControl
@onready var player_gui: InventoryGUI = $HBoxContainer/Player
@onready var external_gui: InventoryGUI = $HBoxContainer/External

var player: Player
var container: ContainerItem

func _ready():
	container_control.player = player
	container_control.container = container
	
	player_gui.inv_owner = container
	external_gui.inv_owner = container
	
	player_gui.update(player.wictl.inventory.items)
	external_gui.update(container.inventory.items)
	
	var viewport = DisplayServer.window_get_size()
	position = Vector2(viewport.x/2, viewport.y/2)
	
	player = null
	container = null

func create(player: Player, container: ContainerItem):
	self.player = player
	self.container = container
