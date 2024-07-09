class_name Sand extends Element

func process(sim: Simulation, row: int, col: int) -> void:
	if sim.in_bounds(row + 1, col) and sim.get_element(row + 1, col) == "empty":
		sim.swap(row, col, row + 1, col)
		return
	var right: bool = sim.in_bounds(row + 1, col + 1) and sim.get_element(row + 1, col + 1) == "empty"
	var left: bool = sim.in_bounds(row + 1, col - 1) and sim.get_element(row + 1, col - 1) == "empty"
	if left and right:
		if Simulation.fast_randf() < 0.5:
			left = false
		else:
			right = false
	if left:
		sim.swap(row, col, row + 1, col - 1)
	elif right:
		sim.swap(row, col, row + 1, col + 1)
	
