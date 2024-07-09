class_name Powder extends Solid

func process(sim: Simulation, row: int, col: int, _data: int) -> void:
	if Simulation.fast_randf() < skip_proportion:
		return
	
	if sim.in_bounds(row + 1, col) and not sim.get_element_resource(row + 1, col) is Solid:
		sim.swap(row, col, row + 1, col)
		return
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

func get_default_data(_sim: Simulation, _row: int, _col: int) -> int:
	return set_byte(0, 1, randi_range(0, 255))
