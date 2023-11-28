extends Node

@onready var main_menu = $CanvasLayer/MainMenu
@onready var address_eny = $CanvasLayer/MainMenu/MarginContainer/VBoxContainer/AddressEntry

const PLAYER = preload("res://player.tscn")
const PORT = 5413
var enet_peer = ENetMultiplayerPeer.new()

enum GenericResult {
	OK,
	SoftError,
	HardError
}

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

func retry_function(process: Callable, retries: int) -> GenericResult:
	# Timer for retries
	var timer: Timer
	var start_timer = func():
		if not timer:
			timer = Timer.new()
			timer.set_wait_time(1)
		self.add_child(timer)
		timer.start()
	
	var exit = func(exit_code: GenericResult):
		if timer: timer.queue_free()
		return exit_code
		
	for i in retries:
		match process.call():
			GenericResult.OK: 
				return exit.call(GenericResult.OK)
			GenericResult.HardError:
				return exit.call(GenericResult.HardError)
		Logger.debug("\tUnable to handle process. Retrying")
		
		start_timer.call()
	
	return exit.call(GenericResult.SoftError)

func _on_host_button_pressed() -> GenericResult:
	Logger.info("Creating host server")
	main_menu.hide()
	
	var server_start = func() -> GenericResult:
		if not enet_peer.create_server(PORT) == Error.OK:
			return GenericResult.OK
		else:
			return GenericResult.SoftError
	
	var upnp_start = func() -> GenericResult: 
		if upnp_setup(): return GenericResult.SoftError
		else: return GenericResult.OK

	match retry_function(server_start, 5):
		GenericResult.SoftError:
			Logger.error("Unable to create Server")
			return GenericResult.SoftError
		GenericResult.HardError:
			Logger.error("Hard error occured while starting UPNP")
			return GenericResult.HardError
		GenericResult.OK:
			Logger.info("Created UPNP")
		
	Logger.debug("\tCreated server on localhost:%s" % PORT)
	
	# match retry_function(upnp_start, 5):
	#	GenericResult.SoftError:
	#		Logger.error("Unable to create UPNP")
	#		return GenericResult.SoftError
	#	GenericResult.HardError:
	#		Logger.error("Hard error occured while starting UPNP")
	#		return GenericResult.HardError
	#	GenericResult.OK:
	#		Logger.info("Created UPNP")
	
	
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	var host_player = multiplayer.get_unique_id()
	add_player(host_player)
	Logger.debug("\tConnected host player (id: %s) to server" % host_player)
	
	Logger.info("Created Server")
	return GenericResult.OK
	
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

func upnp_setup() -> GenericResult:
	Logger.info("Setting up UPNP")
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		Logger.error("UPNP Discover Failed (err %s)" % discover_result)
		return GenericResult.SoftError
	
	if not upnp.get_gateway() or not upnp.get_gateway().is_valid_gateway():
		Logger.error("UPNP Invalid Gateway")
		return GenericResult.SoftError
	
	var map_result = upnp.add_port_mapping(PORT)
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		Logger.error("UPNP Port Mapping Failed (err %s)" % map_result)
		return GenericResult.SoftError
	
	Logger.info("Created UPNP successfully at %s" % upnp.query_external_address())
	return GenericResult.OK
