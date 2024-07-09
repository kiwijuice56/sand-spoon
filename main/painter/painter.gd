class_name Painter extends Node

@export var sim: Simulation

func _input(_event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_position: Vector2 = get_viewport().get_mouse_position() / sim.scale
		paint_circle(int(mouse_position.y), int(mouse_position.x), 4, "sand")
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mouse_position: Vector2 = get_viewport().get_mouse_position() / sim.scale
		paint_circle(int(mouse_position.y), int(mouse_position.x), 4, "empty")

func paint_circle(center_row: int, center_col: int, radius: float, element_name: String) -> void:
	if not sim.in_bounds(center_row, center_col):
		return
	for row in range(-radius, radius + 1):
		for col in range(-radius, radius + 1):
			if row * row + col * col < radius * radius:
				if not sim.in_bounds(row + center_row, col + center_col):
					continue
				sim.set_element(row + center_row, col + center_col, element_name)
