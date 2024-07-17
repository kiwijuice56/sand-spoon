@tool
@icon("res://main/icons/metal_icon.svg")
class_name Ball extends Solid
# Data: reserves bytes 3, 4, 5 for movement state.

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	var angle: float = 2 * PI * get_byte(data, 3) / 255.0
	var direction: Vector2 = Vector2(1, 0).rotated(angle)
	
	var fnew_row: float = row + 2 * direction.y + get_byte(data, 4) / 255.0
	var fnew_col: float = col + 2 * direction.x + get_byte(data, 5) / 255.0
	
	var new_row: int = int(fnew_row)
	var new_col: int = int(fnew_col)
	
	data = set_byte(data, 4, int((fnew_row - new_row) * 255))
	data = set_byte(data, 5, int((fnew_col - new_col) * 255))
	sim.set_data(row, col, data)
	
	if not sim.in_bounds(new_row, new_col) or not (sim.get_element_resource(new_row, new_col) is Empty or sim.get_element_resource(new_row, new_col) is Ball):
		if direction.y < -0.5:
			direction = direction.bounce(Vector2(0, 1))
		elif direction.y > 0.5:
			direction = direction.bounce(Vector2(0, -1))
		elif direction.x > 0.5:
			direction = direction.bounce(Vector2(-1, 0))
		elif direction.x < -0.5:
			direction = direction.bounce(Vector2(1, 0))
		angle = atan2(direction.y, direction.x)
		sim.set_data(row, col, set_byte(data, 3, int(angle / (2 * PI) * 255)))
	else:
		sim.swap(row, col, new_row, new_col)
	
	return true

func get_default_data(sim: Simulation, row: int, col: int) -> int:
	var data: int = super.get_default_data(sim, row, col)
	data = set_byte(data, 3, int(0.0001 * Time.get_ticks_usec()) % 255)
	data = set_byte(data, 4, 0)
	data = set_byte(data, 5, 0)
	return data
