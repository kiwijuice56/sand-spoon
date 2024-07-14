@icon("res://main/icons/powder_icon.svg")
class_name Powder extends Solid

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	if sim.in_bounds(row + 1, col) and not sim.get_element_resource(row + 1, col) is Solid:
		sim.swap(row, col, row + 1, col)
	elif sim.in_bounds(row + 1, col - 1) and not sim.get_element_resource(row + 1, col - 1) is Solid:
		sim.swap(row, col, row + 1, col - 1)
	elif sim.in_bounds(row + 1, col + 1) and not sim.get_element_resource(row + 1, col + 1) is Solid:
		sim.swap(row, col, row + 1, col + 1)
	return true
