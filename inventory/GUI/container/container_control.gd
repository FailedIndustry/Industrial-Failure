extends Node2D
class_name ContainerGUICtrl
## The control for [InventoryGUI]. This is handles player input to the gui and serves 
## as a wrapper around [InventoryGUI]. This has not authority on [Inventory], only
## [Player] has this, but it will call [Player] for such things.

const ITEM_MENU = preload("res://inventory/GUI/ItemMenu.tscn")
## The visual representation of the slot that has been grabbed. This only replicates
## texture and quantity label. 
##
## [member grabbed_slot] is for actually accessing the actual grabbed slot.
@onready var grabbed_visual = $GrabbedSlot

## The GUI panel of the inventory.
@onready var container_gui: InventoryGUI = $"../HBoxContainer/External"
@onready var player_gui: InventoryGUI = $"../HBoxContainer/Player"

@export var player: Player
@export var container: ContainerItem

## A pointer to the slot that is grabbed. This is not the visual representation that is
## seen that has reduced alpha.
var grabbed_slot: Slot
## Menu of actions a player can take on an object. Appears when right-clicked
var item_menu

func _ready():
	player_gui.inv_owner = container
	container_gui.inv_owner = container

## If the Inventory GUI panel is clicked
func _player_gui_clicked(_button_index: int):
	grabbed_visual.hide()
	grabbed_slot = null
	clear_item_menu()

func _external_gui_clicked(_button_index: int):
	grabbed_visual.hide()
	grabbed_slot = null
	clear_item_menu()

## If the player clicks behind the invnetory GUI panel.
func _background_gui_input(event):
	if event is InputEventMouseButton \
			and event.is_pressed() \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and grabbed_slot \
			and grabbed_visual:
		player.wictl.take_from_container(container, grabbed_slot.item)
		player.wictl.drop_item(grabbed_slot.item)
		grabbed_slot = null
		grabbed_visual.hide()

func _slot_clicked(slot: Slot, button_index: int):
	if button_index == MOUSE_BUTTON_LEFT:
		press_on_item(slot)
	elif button_index == MOUSE_BUTTON_RIGHT:
		show_item_menu(slot)

## Moves [member grabbed_slot] to the mouse location
func _physics_process(_delta):
	if grabbed_slot and grabbed_visual:
		grabbed_visual.global_position = get_global_mouse_position() + Vector2(10,10)


## Sets [member grabbed_slot] to point to the slot we grabbed and replicates this to
## [member grabbed_visual] for a visual representation.
func _set_grabbed(slot: Slot) -> void:
	grabbed_visual.set_item(slot.item)
	grabbed_slot = slot

## "Unsets" [member grabbed_visual] AND [member grabbed_slot]
##
## Hides and sets [member grabbed_visual] to error values (in case that it is shown or is used 
## accidentally. [member grabbed_slot] is set to null
func _unset_grabbed() -> void:
	grabbed_visual.unset_item()
	grabbed_slot = null

func swap_item(gui: InventoryGUI, slot: Slot):
	# First we have to make sure that there is a slot grabbed and we are swapping in the same
	# category
	if grabbed_slot \
			and grabbed_slot.item.item_type.category == slot.item.item_type.category:
		Logger.debug("Swapping %s and %s" % [slot.item.item_type.name, grabbed_slot.item.item_type.name])
		
		gui.swap_slots(slot, grabbed_slot)
		# After swapping the items in the inventory, get rid of the visual
		_unset_grabbed()

## Clears [member item_menu] (item menu) and swaps if an item is grabbed or grabbs the item if not
func press_on_item(slot: Slot):
	clear_item_menu()
	
	if grabbed_slot:
		if grabbed_slot.item.owner == slot.item.owner:
			if slot.item.owner == player:
				swap_item(player_gui, slot)
			else:
				swap_item(container_gui, slot)
		elif grabbed_slot.item.owner == player:
			container.take_from_player(player, grabbed_slot.item)
		elif grabbed_slot.item.owner == container:
			player.wictl.take_from_container(container, grabbed_slot.item)
		else:
			Logger.error("container_control.press_on_item: Grabbed slot is not from an attached container or player")
	else:
		_set_grabbed(slot)

func clear_item_menu():
	if item_menu:
		item_menu.queue_free()
		item_menu = null

## If there is not a grabbed slot, this will show the item menu on the slot
func show_item_menu(slot: Slot):
	clear_item_menu()
	
	if not grabbed_slot:
		Logger.info("Creating item slot menu")
		item_menu = ITEM_MENU.instantiate()
		item_menu.z_index = 1000
		add_child(item_menu)
		 # to slightly offset for better usability
		item_menu.global_position = get_global_mouse_position() + Vector2(10, 10)

func _inventory_gui_clicked(gui: InventoryGUI, button_index: int):
	if gui == player_gui: _player_gui_clicked(button_index)
	elif gui == container_gui: _external_gui_clicked(button_index)
