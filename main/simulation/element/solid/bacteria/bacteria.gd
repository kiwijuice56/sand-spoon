@tool
@icon("res://main/icons/bacteria_icon.svg")
class_name Bacteria extends Solid
# Data: assumes byte 2 for touch count

@export_range(0, 1) var growth_rate: float = 0.1
@export_range(0, 1) var surround_tolerance: float
@export_range(0, 1) var loneliness_tolerance: float
@export var home_material: String

var surround_min: int
var surround_max: int

func initialize() -> void:
	super.initialize()
	surround_max = int(surround_tolerance * 8)
	surround_min = int(loneliness_tolerance * 8)
	surround_min = min(surround_min, surround_max - 1)
	surround_min = max(0, surround_min)

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	if Simulation.fast_randf() < growth_rate:
		grow(sim, row + 1, col)
		grow(sim, row - 1, col)
		grow(sim, row, col + 1)
		grow(sim, row, col - 1)
	
	var touch_count: int = sim.get_touch_count(row, col, unique_name)
	if touch_count > surround_max or touch_count < surround_min:
		sim.set_element(row, col, home_material)
		return false
	
	sim.set_data(row, col, set_byte(data, 2, touch_count))
	
	return true

func get_color(_sim: Simulation, _row: int, _col: int, data: int) -> Color:
	return pixel_color.gradient.sample(get_byte(data, 2) / 8.0)

func grow(sim: Simulation, row: int, col: int) -> void:
	if not sim.in_bounds(row, col):
		return
	if sim.get_element(row, col) == home_material:
		sim.set_element(row, col, unique_name)
