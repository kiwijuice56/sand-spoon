@tool
@icon("res://main/icons/solid_icon.svg")
class_name Solid extends Element
# Data: assumes byte 2 for color index, assigned randomly

func get_color(_sim: Simulation, _row: int, _col: int, data: int) -> Color:
	return pixel_color.gradient.sample(get_byte(data, 2) / 255.0)

func get_default_data(sim: Simulation, row: int, col: int) -> int:
	var data: int = super.get_default_data(sim, row, col)
	return set_byte(data, 2, randi_range(0, 255))
