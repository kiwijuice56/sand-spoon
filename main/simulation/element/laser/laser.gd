@tool
@icon("res://main/icons/laser_icon.svg")
class_name Laser extends Element

@export var laser_color: Color
@export_range(0, 1, 0.25) var reach: float = 0.25
@export var ireach: int = 1

func initialize() -> void:
	super.initialize()
	ireach = round(4 * reach)

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	for i in range(1, 1 + reach):
		if not Explosion.grow(sim, row + i, col, unique_name):
			break
	return true

func get_color(_sim: Simulation, _row: int, _col: int, _data: int) -> Color:
	return laser_color
