extends TextureProgressBar

@onready var player = $".."

func _ready():
	update()

func update():
	value = player.health * 100 / player.maxHealth
