extends ItemType
class_name EquipableItem

func _init():
	stackable = false
	name = "EquipableItem"
	description = "description"
	actions[1].append("Equip")
	actions[0].append(func equip(player: Player):
		if player != ServerGlobal.player:
			Logger.error("%s.equip: Tried to equip item you don't own" % name)
		# TODO impliment equipment logic
	)
