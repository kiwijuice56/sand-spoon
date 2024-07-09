class_name Liquid extends Element

## Range of colors based on height.
@export var color_gradient: GradientTexture1D

@export_group("Fluid dynamics")
## Thickness of the liquid.
@export var viscosity: float
## Denser fluids can sink through less dense fluids.
@export var density: float 

var dispersion: int

func initialize() -> void:
	dispersion = 4 - int(3.0 * viscosity)

func process(sim: Simulation, row: int, col: int, data: int) -> void:
	if Simulation.fast_randf() < skip_proportion:
		return
	
	if can_swap(sim, row + 1, col, data):
		sim.swap(row, col, row + 1, col)
		return
	
	var end: int = dispersion + 1
	var dir: int = 1
	if Simulation.fast_randf() < 0.5:
		end = -dispersion - 1
		dir = -1
	
	for i in range(dir, end, dir):
		if not can_swap(sim, row, col + i, data):
			if not i - dir == 0:
				sim.swap(row, col, row, col + i - dir)
			return
	sim.swap(row, col, row, col + dispersion * dir)

func get_color(sim: Simulation, row: int, _col: int, _data: int) -> Color:
	return color_gradient.gradient.sample(1.0 - float(row) / sim.simulation_size.y)

func can_swap(sim: Simulation, row: int, col: int, _data: int) -> bool:
	if not sim.in_bounds(row, col):
		return false
	var element: Element = sim.get_element_resource(row, col)
	if element is Solid:
		return false
	if element is Liquid and element.density >= density:
		return false
	return true
