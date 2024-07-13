@icon("res://main/icons/fluid_icon.svg")
class_name Fluid extends Element

## Range of colors based on height.
@export var color_gradient: GradientTexture1D

@export_group("Fluid dynamics")

@export var move_vertical_proportion: float = 0.9
## Thickness of the liquid.
@export_range(0, 1) var viscosity: float
## Denser fluids can sink through less dense fluids.
@export_range(0, 4000, 0.01, "or_greater", "suffix:kg/m^3") var density: float 
@export var gravity_down: bool = true

var dispersion: int
var gravity_dir: int 

func initialize() -> void:
	super.initialize()
	dispersion = 4 - int(3.0 * viscosity)
	gravity_dir = 1 if gravity_down else -1

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	
	if Simulation.fast_randf() < move_vertical_proportion and can_swap(sim, row + gravity_dir, col, data):
		sim.swap(row, col, row + gravity_dir, col)
		return true
	
	var end: int = dispersion + 1
	var dir: int = 1
	if Simulation.fast_randf() < 0.5:
		end = -end
		dir = -1
	
	for i in range(dir, end, dir):
		if not can_swap(sim, row, col + i, data):
			if not i == dir:
				sim.swap(row, col, row, col + i - dir)
			return true
	sim.swap(row, col, row, col + dispersion * dir)
	
	return true

func get_color(sim: Simulation, row: int, _col: int, _data: int) -> Color:
	return color_gradient.gradient.sample(1.0 - float(row) / sim.simulation_size.y)

func can_swap(sim: Simulation, row: int, col: int, _data: int) -> bool:
	if not sim.in_bounds(row, col):
		return false
	var element: Element = sim.get_element_resource(row, col)
	if element is Empty:
		return true
	if element is Solid or element is Laser:
		return false
	if gravity_down:
		if element is Fluid and element.density >= density:
			return false
	else:
		if element is Fluid and element.density <= density:
			return false
	return true
