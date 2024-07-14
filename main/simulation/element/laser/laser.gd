@tool
@icon("res://main/icons/laser_icon.svg")
class_name Laser extends Element

@export_group("Beam dynamics")
@export_range(0, 1, 0.25) var reach: float = 0.25

var ireach: int = 1

func initialize() -> void:
	super.initialize()
	ireach = int(round(4 * reach))

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	for i in range(1, 1 + ireach):
		if not Explosion.grow(sim, row + i, col, unique_name):
			break
	return true
