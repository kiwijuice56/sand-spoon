class_name Solid extends Element

## Range of colors each cell can have.
@export var color_gradient: GradientTexture1D

func get_color(_sim: Simulation, _row: int, _col: int, data: int) -> Color:
	return color_gradient.gradient.sample(get_byte(data, 1) / 255.0)
