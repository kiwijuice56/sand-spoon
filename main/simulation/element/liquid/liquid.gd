class_name Liquid extends Element

@export var color_gradient: GradientTexture1D
@export var viscosity: float

var dispersion: int

func initialize() -> void:
	dispersion = 8 - int(7.0 * viscosity)

func process(sim: Simulation, row: int, col: int, _data: int) -> void:
	if Simulation.fast_randf() < skip_proportion:
		return
	
	if sim.in_bounds(row + 1, col) and sim.get_element(row + 1, col) == "empty":
		sim.swap(row, col, row + 1, col)
		return
	
	var end: int = dispersion + 1
	var dir: int = 1
	if Simulation.fast_randf() < 0.5:
		end = -dispersion - 1
		dir = -1
	
	for i in range(0, end, dir):
		if sim.in_bounds(row, col + i) and sim.get_element(row, col + i) == "empty":
			sim.swap(row, col, row, col + i)
			return

func get_color(sim: Simulation, row: int, col: int, _data: int) -> Color:
	return color_gradient.gradient.sample(1.0 - float(row) / sim.simulation_size.y)
