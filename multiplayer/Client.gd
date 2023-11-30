extends "res://multiplayer/Multiplayer.gd"

var join_server = func join_server(
	remote_server, 
	enet_peer: ENetMultiplayerPeer
):
	Logger.info("Joining server")
	Logger.debug("\tServer: %s:%d" % [remote_server, PORT])
	
	if enet_peer.create_client(remote_server, PORT) == Error.OK:
		Logger.info("Connected to server")
		enet_peer.get_host().compress(COMPRESSION)
		return GenericResult.OK
	else:
		Logger.error("Unable to connect to server")
		return GenericResult.SoftError
