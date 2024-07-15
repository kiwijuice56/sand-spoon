@tool
@icon("res://main/icons/lightning_icon.svg")
class_name Lightning extends Element
# Data: assumes byte 2 for excitation state.

@export_group("Electricity dynamics")
@export_range(0, 1) var fall_proportion: float = 0.9
@export var unexcited_decay_proportion: float = 0.3
@export var unexcited_decay_element: String

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	if get_byte(data, 2) == 0:
		for i in range(0, 10):
			if i == 4:
				continue
			var check_row: int = row + i / 3 - 1
			var check_col: int = col + i % 3 - 1
			if not sim.in_bounds(check_row, check_col):
				kill(sim, row, col, data)
				return false
			var element: Element = sim.get_element_resource(check_row, check_col)
			if element is Empty:
				continue
			if element == self and get_byte(sim.get_data(check_row, check_col), 2) == 0:
				continue
			kill(sim, row, col, data)
			return false
		var rand_row: int = row + (1 if Simulation.fast_randf() < fall_proportion else -1)
		var rand_col: int = col + randi_range(-1, 1)
		if sim.in_bounds(rand_row, rand_col) and sim.get_element_resource(rand_row, rand_col) is Empty and sim.get_touch_count(rand_row, rand_col, unique_name) <= 2:
			sim.set_element(rand_row, rand_col, unique_name)
	else:
		if sim.fast_randf() < unexcited_decay_proportion:
			sim.set_element(row, col, unexcited_decay_element)
			return false
		col += randi_range(-1, 1)
		if sim.in_bounds(row + 1, col):
			sim.swap(row, col, row + 1, col)
	return true

func kill(sim: Simulation, row: int, col: int, data: int) -> void:
	sim.set_data(row, col, set_byte(data, 2, 1), true)

func get_color(_sim: Simulation, _row: int, _col: int, data: int) -> Color:
	return pixel_color.gradient.sample(1 - get_byte(data, 2))

func get_default_data(sim: Simulation, row: int, col: int) -> int:
	var data: int = super.get_default_data(sim, row, col)
	return set_byte(data, 2, 0)
