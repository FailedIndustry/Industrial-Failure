extends "res://multiplayer/Multiplayer.gd"

var start_server = func start_server(
	port: int,
	enet_peer: ENetMultiplayerPeer,
	upnp: bool = false,
) -> GenericResult:
	Logger.info("Creating host server")
	
	var server_start = func() -> GenericResult:
		if enet_peer.create_server(port) == Error.OK:
			return GenericResult.OK
		else:
			return GenericResult.SoftError
	
	var upnp_start = func() -> GenericResult: 
		if upnp_setup.call(): return GenericResult.SoftError
		else: return GenericResult.OK

	Logger.info("Starting server")
	var server_result = await retry_function(server_start, 5)
	if server_result == GenericResult.OK: 
		Logger.debug("\tCreated server on localhost:%s" % port)
	else: 
		return server_result
	
	if upnp:
		var upnp_result = await retry_function(func(): upnp_start.call(port), 5)
		if upnp_result == GenericResult.OK:
			Logger.debug("\tCreated upnp on localhost:%s" % port)
		else: 
			return upnp_result
	
	Logger.info("Created Server")
	return GenericResult.OK

var upnp_setup = func upnp_setup(port: int) -> GenericResult:
	Logger.info("Setting up UPNP")
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	if discover_result != UPNP.UPNP_RESULT_SUCCESS:
		Logger.error("UPNP Discover Failed (err %s)" % discover_result)
		return GenericResult.SoftError
	
	if not upnp.get_gateway() or not upnp.get_gateway().is_valid_gateway():
		Logger.error("UPNP Invalid Gateway")
		return GenericResult.SoftError
	
	var map_result = upnp.add_port_mapping(port)
	if map_result != UPNP.UPNP_RESULT_SUCCESS:
		Logger.error("UPNP port Mapping Failed (err %s)" % map_result)
		return GenericResult.SoftError
	
	Logger.info("Created UPNP successfully at %s" % upnp.query_external_address())
	return GenericResult.OK
