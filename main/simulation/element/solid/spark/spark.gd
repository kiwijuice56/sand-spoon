@tool
@icon("res://main/icons/spark_icon.svg")
class_name Spark extends Solid
# Data: reserves bytes 3, 4, 5 for movement state.

@export var speed: int = 4
@export_range(0, 1) var angle_lerp_speed: float = 0.4

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if not super.process(sim, row, col, data):
		return false
	var angle: float = 2 * PI * get_byte(data, 3) / 255.0
	
	var direction: Vector2 = Vector2(1, 0).rotated(angle)
	
	var fnew_row: float = row + speed * direction.y + get_byte(data, 4) / 255.0
	var fnew_col: float = col + speed * direction.x + get_byte(data, 5) / 255.0
	
	var new_row: int = int(fnew_row)
	var new_col: int = int(fnew_col)
	
	data = set_byte(data, 4, int((fnew_row - new_row) * 255))
	data = set_byte(data, 5, int((fnew_col - new_col) * 255))
	
	angle = lerp_angle(angle, PI / 2, angle_lerp_speed)
	data = set_byte(data, 3, int(angle / (2 * PI) * 255))
	
	sim.set_data(row, col, data)
	
	if sim.in_bounds(new_row, new_col) and (sim.get_element_resource(new_row, new_col) is Empty or sim.get_element(new_row, new_col) == unique_name):	
		sim.swap(row, col, new_row, new_col)
		return false
	return true

func get_default_data(sim: Simulation, row: int, col: int) -> int:
	var data: int = super.get_default_data(sim, row, col)
	data = set_byte(data, 3, int(randf_range(-PI / 4, -3 * PI / 4) / (2 * PI) * 255))
	data = set_byte(data, 4, 0)
	data = set_byte(data, 5, 0)
	return data
