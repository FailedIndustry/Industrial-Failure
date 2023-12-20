extends Node
var counter = 0
@export var OBJECT = preload("res://testing/Gun.tscn")
@export var wait = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	counter += 1
	if counter % (wait + 1) == 0:
		if counter % 60 == 0:
			Logger.info("objects: %s" % counter)
		var object = OBJECT.instantiate()
		add_child(object)
