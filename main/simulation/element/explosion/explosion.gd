@icon("res://main/icons/element_icon.svg")
class_name Explosion extends Element

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	grow(sim, row + 1, col)
	grow(sim, row - 1, col)
	grow(sim, row, col + 1)
	grow(sim, row, col - 1)
	return true

func grow(sim: Simulation, row: int, col: int) -> void:
	if not sim.in_bounds(row, col):
		return
	if sim.fast_randf() < sim.get_element_resource(row, col).explosion_resistance:
		return
	sim.set_element(row, col, "explosion")
