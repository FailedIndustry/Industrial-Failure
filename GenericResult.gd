enum GenericError {
	SoftError,
	HardError
}

class GenericResult:
	var data
	var err: GenericError
	
	func _init(data, err: GenericError):
		self.data = data
		self.err = err
