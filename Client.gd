extends "res://Multiplayer.gd"

var join_server = func join_server(
	remote_server, 
	port: int, 
	enet_peer: ENetMultiplayerPeer
):
	Logger.info("Joining server")
	Logger.debug("\tServer: %s:%d" % [remote_server, port])
	
	if enet_peer.create_client(remote_server, port) == Error.OK:
		Logger.info("Connected to server")
		return GenericResult.OK
	else:
		Logger.error("Unable to connect to server")
		return GenericResult.SoftError
