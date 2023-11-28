extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_eny = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const PLAYER = preload("res://player.tscn")
const PORT = 5413
var enet_peer = ENetMultiplayerPeer.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	Logger.debug("Main scene ready")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		Logger.info("Exiting game")
		get_tree().quit()


func _on_host_button_pressed():
	Logger.info("Creating host server")
	main_menu.hide()
	
	var timer: Timer
	for i in 5:
		if enet_peer.create_server(PORT): break
		
		Logger.warn("Unable to create enet host. Retrying")
		if not timer:
			timer = Timer.new()
			timer.set_wait_time(1)
		self.add_child(timer)
		timer.start()
		
	timer.queue_free()
		
	Logger.debug("\tCreated server on localhost:%s" % PORT)
	
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	var host_player = multiplayer.get_unique_id()
	add_player(host_player)
	Logger.debug("\tConnected host player (id: %s) to server" % host_player)
	Logger.info("Created Server")
	
func remove_player(peer_id):
	Logger.info("Removing player from scene")
	Logger.debug("\tPlayer: %s" % peer_id)
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	else:
		Logger.warn("\tAttempted to remove non-existant player")

func _on_join_button_pressed():
	var remote_server = "localhost"
	Logger.info("Joining server")
	Logger.debug("\tServer: %s:%d" % [remote_server, PORT])
	
	main_menu.hide()
	
	enet_peer.create_client(remote_server, PORT)
	multiplayer.multiplayer_peer = enet_peer
	Logger.info("Connected to server")
	
func add_player(peer_id):
	Logger.info("Creating player")
	Logger.debug("Player id: %s" % peer_id)
	
	var player = PLAYER.instantiate()
	player.name = str(peer_id)
	add_child(player)
	Logger.info("Created Player")

func upnp_setup():
	Logger.info("Setting up UPNP")
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Discover Failed (err %s)" % discover_result)
	
	assert(upnp.get_gateway() \
			and upnp.get_gateway().is_valid_gateway(), \
		"UPNP Invalid Gateway")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed (err %s)" % map_result)
	
	Logger.info("Created UPNP Successfully")
