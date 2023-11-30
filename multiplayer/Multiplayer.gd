extends Node
const COMPRESSION = ENetConnection.COMPRESS_RANGE_CODER
const MAX_PLAYERS = 4095
const PORT = 5413

enum GenericResult {
	OK,
	SoftError,
	HardError
}

## Retry a function a certain amount of times. If the function returns 0,
## it is a success. If it returns 2, it is stops immediately (see 
## [enum GenericResult])
func retry_function(process: Callable, retries: int) -> GenericResult:
	for i in retries:
		match process.call():
			GenericResult.OK: 
				Logger.info("retry_function: Success")
				return GenericResult.OK
			GenericResult.HardError:
				Logger.error("retry_function: Encountered hard error")
				return GenericResult.HardError
		
		Logger.debug("\tretry_function: Unable to handle process. Retrying")
	
	return GenericResult.SoftError
