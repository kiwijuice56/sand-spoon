class_name Powder extends Solid

@export var color_variation: float = 0.25

var color_a: Color
var color_b: Color
var color_c: Color

func initialize() -> void:
	color_a = color
	color_b = color.lightened(color_variation)
	color_c = color.lightened(2 * color_variation)

func process(sim: Simulation, row: int, col: int, _data: int) -> void:
	if Simulation.fast_randf() < skip_proportion:
		return
	
	if sim.in_bounds(row + 1, col) and not sim.get_element_resource(sim.get_element(row + 1, col)) is Solid:
		sim.swap(row, col, row + 1, col)
		return
	var right: bool = sim.in_bounds(row + 1, col + 1) and not sim.get_element_resource(sim.get_element(row + 1, col + 1)) is Solid
	var left: bool = sim.in_bounds(row + 1, col - 1) and not sim.get_element_resource(sim.get_element(row + 1, col - 1)) is Solid
	if left and right:
		if Simulation.fast_randf() < 0.5:
			left = false
		else:
			right = false
	if left:
		sim.swap(row, col, row + 1, col - 1)
	elif right:
		sim.swap(row, col, row + 1, col + 1)

func get_color(_sim: Simulation, _row: int, _col: int, data: int) -> Color:
	if data == 0:
		return color_a
	elif data == 1:
		return color_b
	return color_c

func get_default_data(sim: Simulation, _row: int, _col: int) -> int:
	return randi_range(0, 2)
