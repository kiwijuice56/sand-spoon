class_name Sand extends Element

func process(sim: Simulation, row: int, col: int) -> void:
	if sim.in_bounds(row + 1, col) and sim.get_element(row + 1, col) == "empty":
		sim.swap(row, col, row + 1, col)
	
