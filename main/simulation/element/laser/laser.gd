@icon("res://main/icons/laser_icon.svg")
class_name Laser extends Element

@export var laser_color: Color
@export var reach: int = 1

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	for i in range(1, 1 + reach):
		if not Explosion.grow(sim, row + i, col, unique_name):
			break
	return true

func get_color(_sim: Simulation, _row: int, _col: int, _data: int) -> Color:
	return laser_color
