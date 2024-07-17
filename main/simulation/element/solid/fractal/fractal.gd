@tool
@icon("res://main/icons/bacteria_icon.svg")
class_name Fractal extends Solid
# Data: reserves bytes 3, 4, 5 for movement state, and 6 for alive state

@export var speed: int = 1
@export var branch_angle: float = 2 * PI / 11
@export var split_proportion: float = 0.1

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	if get_byte(data, 6) == 0:
		return true
	
	var angle: float = 2 * PI * get_byte(data, 3) / 255.0
	var random_flip: float = -1 if Simulation.fast_randf() < 0.5 else 1
	
	if Simulation.fast_randf() < split_proportion:
		for new_angle in [branch_angle / 2, -branch_angle / 2]:
			new_angle = new_angle * random_flip + angle
			
			var direction: Vector2 = Vector2(1, 0).rotated(new_angle)
			
			var fnew_row: float = row + speed * direction.y + get_byte(data, 4) / 255.0
			var fnew_col: float = col + speed * direction.x + get_byte(data, 5) / 255.0
			var new_row: int = int(fnew_row)
			var new_col: int = int(fnew_col)
			
			if not sim.in_bounds(new_row, new_col) or not sim.get_element_resource(new_row, new_col) is Empty:
				continue
			
			sim.set_element(new_row, new_col, unique_name)
			
			var new_data: int = set_byte(data, 4, int((fnew_row - new_row) * 255))
			new_data = set_byte(data, 5, int((fnew_col - new_col) * 255))
			
			new_data = set_byte(data, 3, int(new_angle / (2 * PI) * 255))
			
			sim.set_data(new_row, new_col, new_data)
	else:
		var direction: Vector2 = Vector2(1, 0).rotated(angle)
		
		var fnew_row: float = row + speed * direction.y + get_byte(data, 4) / 255.0
		var fnew_col: float = col + speed * direction.x + get_byte(data, 5) / 255.0
		var new_row: int = int(fnew_row)
		var new_col: int = int(fnew_col)
		
		if sim.in_bounds(new_row, new_col) and sim.get_element_resource(new_row, new_col) is Empty:
			sim.set_element(new_row, new_col, unique_name)
			var new_data: int = set_byte(data, 4, int((fnew_row - new_row) * 255))
			new_data = set_byte(data, 5, int((fnew_col - new_col) * 255))
			sim.set_data(new_row, new_col, new_data)
			
		sim.set_data(row, col, set_byte(data, 6, 0))
	return true

func get_color(sim: Simulation, _row: int, _col: int, data: int) -> Color:
	return pixel_color.gradient.sample(get_byte(data, 3) / 255.0)

func get_default_data(sim: Simulation, row: int, col: int) -> int:
	var data: int = super.get_default_data(sim, row, col)
	data = set_byte(data, 3, randi() % 255)
	data = set_byte(data, 4, 0)
	data = set_byte(data, 5, 0)
	data = set_byte(data, 6, 1)
	return data
