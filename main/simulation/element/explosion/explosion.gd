@icon("res://main/icons/explosion_icon.svg")
class_name Explosion extends Element

@export var explosion_color: Color

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	grow(sim, row + 1, col, unique_name)
	grow(sim, row - 1, col, unique_name)
	grow(sim, row, col + 1, unique_name)
	grow(sim, row, col - 1, unique_name)
	return true

func get_color(_sim: Simulation, _row: int, _col: int, _data: int) -> Color:
	return explosion_color

static func grow(sim: Simulation, row: int, col: int, element: String) -> bool:
	if not sim.in_bounds(row, col):
		return false
	if sim.fast_randf() < sim.get_element_resource(row, col).explosion_resistance:
		return false
	sim.set_element(row, col, element)
	return true
