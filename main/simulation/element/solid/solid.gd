class_name Solid extends Element
# Data: assumes byte 1 for color index, assigned randomly

## Range of colors each cell can have.
@export var color_gradient: GradientTexture1D

func get_color(_sim: Simulation, _row: int, _col: int, data: int) -> Color:
	return color_gradient.gradient.sample(get_byte(data, 1) / 255.0)

func get_default_data(sim: Simulation, row: int, col: int) -> int:
	var data: int = super.get_default_data(sim, row, col)
	return set_byte(data, 1, randi_range(0, 255))
