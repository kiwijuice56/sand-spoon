@tool
@icon("res://main/icons/metal_icon.svg")
class_name Metal extends Solid

@export var heat_gradient: GradientTexture1D

func initialize() -> void:
	super.initialize()
	color_is_temperature_dependent = true

func get_color(sim: Simulation, row: int, col: int, data: int) -> Color:
	return super.get_color(sim, row, col, data).blend(heat_gradient.gradient.sample(get_temperature(data) / 65535.0))
