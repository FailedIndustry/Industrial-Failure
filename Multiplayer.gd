extends Node


enum GenericResult {
	OK,
	SoftError,
	HardError
}

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
