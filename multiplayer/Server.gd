extends "res://multiplayer/Multiplayer.gd"

var start_server = func start_server(
	enet_peer: ENetMultiplayerPeer,
	upnp: bool = false,
) -> GenericResult:
	Logger.info("Creating host server")
	
	# Server function to be later passed into retry function
	var enet_server_start = func() -> GenericResult:
		if enet_peer.create_server(PORT, 4095) == Error.OK:
			return GenericResult.OK
		else:
			return GenericResult.SoftError
	
	# Upnp to be later passed to retry function
	var upnp_start = func() -> GenericResult: 
		if upnp_setup.call(): return GenericResult.SoftError
		else: return GenericResult.OK

	Logger.info("Starting server")
	var server_result = retry_function(enet_server_start, 5)
	if server_result == GenericResult.OK: 
		Logger.debug("\tCreated server on localhost:%s" % PORT)
	else: 
		return server_result
	
	if upnp:
		var upnp_result = retry_function(upnp_start, 5)
		if upnp_result == GenericResult.OK:
			Logger.debug("\tCreated upnp on localhost:%s" % PORT)
		else: 
			return upnp_result
	
	enet_peer.get_host().compress(COMPRESSION)
	Logger.info("Created Server")
	return GenericResult.OK

var upnp_setup = func upnp_setup() -> GenericResult:
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
		Logger.error("UPNP port Mapping Failed (err %s)" % map_result)
		return GenericResult.SoftError
	
	Logger.info("Created UPNP successfully at %s" % upnp.query_external_address())
	return GenericResult.OK
