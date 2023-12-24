extends ItemType
class_name EquipableItem



func _init():
	stackable = false
	name = "EquipableItem"
	description = "description"
	actions.append([])
	actions.append([])
	actions[0].append(func equip(player: Player):
		Logger.error("Test equip")
		# TODO impliment equipment logic
	)
	actions[1].append("Equip")
