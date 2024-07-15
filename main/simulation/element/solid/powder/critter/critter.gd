@tool
@icon("res://main/icons/bacteria_icon.svg")
class_name Critter extends Powder

@export_range(0, 1) var travel_proportion: float = 0.1
@export_range(0, 1) var jump_proportion: float = 0.1
@export_range(0, 1) var jump_force: float = 0.5

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	if Simulation.fast_randf() < jump_proportion and on_ground(sim, row, col):
		var check_jump: int = int(Simulation.fast_randf() * jump_force * 5)
		for i in range(1, 1 + check_jump):
			if not can_swap(sim, row - i, col):
				if not i == 1:
					sim.swap(row, col, row - i - 1, col)
				return true
		sim.swap(row, col, row - check_jump - 1, col)
		return true
	if Simulation.fast_randf() < travel_proportion:
		var dir: int = -1 if Simulation.fast_randf() < 0.5 else 1
		if can_swap(sim, row, col + dir):
			sim.swap(row, col, row, col + dir)
			return true
	
	var touch_count: int = sim.get_touch_count(row, col, unique_name)
	sim.set_data(row, col, set_byte(data, 2, touch_count))
	
	return true

func get_color(_sim: Simulation, _row: int, _col: int, data: int) -> Color:
	return pixel_color.gradient.sample(get_byte(data, 2) / 8.0)

static func on_ground(sim: Simulation, row: int, col: int) -> bool:
	if row == sim.simulation_size.y - 1:
		return true
	return sim.in_bounds(row + 1, col) and sim.get_element_resource(row + 1, col) is Solid

static func can_swap(sim: Simulation, row: int, col: int) -> bool:
	return sim.in_bounds(row, col) and sim.get_element_resource(row, col) is Empty
