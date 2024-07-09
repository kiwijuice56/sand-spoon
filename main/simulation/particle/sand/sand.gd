class_name Sand extends Particle

func _init() -> void:
	color = Color("#fcb103").lightened(randf_range(0.0, 0.25))

func process(sim: Simulation, row: int, col: int) -> void:
	if sim.in_bounds(row + 1, col) and sim.get_particle(row + 1, col) is Empty:
		sim.swap(row, col, row + 1, col)
	var dir: int = 1 if sim.rand() < 0.5 else -1
	if sim.in_bounds(row + 1, col + dir) and sim.get_particle(row + 1, col + dir) is Empty:
		sim.swap(row, col, row + 1, col + dir)
	dir = 1 - dir
	if sim.in_bounds(row + 1, col + dir) and sim.get_particle(row + 1, col + dir) is Empty:
		sim.swap(row, col, row + 1, col + dir)
