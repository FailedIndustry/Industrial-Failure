extends ProgressBar

var player: Player

func set_player(player: Player):
	self.player = player
	player.on_health_change.connect(self.update)


func update():
	value = player.health
