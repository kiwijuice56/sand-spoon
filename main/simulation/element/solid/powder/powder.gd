@icon("res://main/icons/powder_icon.svg")
class_name Powder extends Solid

@export var move_down_proportion: float = 0.9

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	if sim.in_bounds(row + 1, col) and not sim.get_element_resource(row + 1, col) is Solid and Simulation.fast_randf() < move_down_proportion:
		sim.swap(row, col, row + 1, col)
		return true
	var right: bool = sim.in_bounds(row + 1, col + 1) and not sim.get_element_resource(row + 1, col + 1) is Solid
	var left: bool = sim.in_bounds(row + 1, col - 1) and not sim.get_element_resource(row + 1, col - 1) is Solid
	if left and right:
		if Simulation.fast_randf() < 0.5:
			left = false
		else:
			right = false
	if left:
		sim.swap(row, col, row + 1, col - 1)
	elif right:
		sim.swap(row, col, row + 1, col + 1)
	return true
