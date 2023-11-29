extends Node

const PLAYER = preload("res://player.tscn")
const Server = preload("res://Server.gd")
const Client = preload("res://Client.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	Logger.set_logger_format(Logger.LOG_FORMAT_FULL)
	
	var datetime = Time.get_datetime_string_from_system()
	var filelogger = Logger.add_appender(
		FileAppender.new("res://.log/%s.log" % datetime)
	)
	filelogger.logger_level = Logger.LOG_LEVEL_FINE
	
	var consolelogger = Logger.add_appender(ConsoleAppender.new())
	consolelogger.logger_level = Logger.LOG_LEVEL_DEBUG
	Logger.debug("Main scene ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _unhandled_input(event):
	if Input.is_action_just_pressed("quit"):
		Logger.info("Exiting game")
		get_tree().quit()

func add_player(peer_id):
	Logger.info("Creating player")
	Logger.debug("Player id: %s" % peer_id)
	
	var player = PLAYER.instantiate()
	player.name = str(peer_id)
	add_child(player)
	Logger.info("Created Player")

func remove_player(peer_id):
	Logger.info("Removing player from scene")
	Logger.debug("\tPlayer: %s" % peer_id)
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	else:
		Logger.warn("\tAttempted to remove non-existant player")

const PORT = 5413
@onready var main_menu = $MainMenu/CanvasLayer/MainMenu

func _on_host_button_pressed():
	var enet_peer = ENetMultiplayerPeer.new()
	var server = Server.new()
	
	if server.start_server.call(PORT, enet_peer, false) != 0: return 
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	main_menu.hide()
	
	var host_player = multiplayer.get_unique_id()
	add_player(host_player)

func _on_join_button_pressed():
	var enet_peer = ENetMultiplayerPeer.new()
	var client = Client.new()
	
	if client.join_server.call('localhost', PORT, enet_peer) !=0 : return
	main_menu.hide()
	multiplayer.multiplayer_peer = enet_peer
