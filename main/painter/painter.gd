class_name Painter extends Node

@export var sim: Simulation
@export var brush_radius: int

var is_tapping: bool = false
var tap_start: Vector2

var current_element: String = "sand"

func _process(_delta: float) -> void:
	if Input.is_action_pressed("tap"):
		
		var mouse_position: Vector2 = get_viewport().get_mouse_position() / sim.scale
		if not is_tapping:
			tap_start = mouse_position
			is_tapping = true
		paint_line(tap_start, mouse_position, brush_radius, current_element)
		
		tap_start = mouse_position
	
	if Input.is_action_just_released("tap"):
		is_tapping = false

func paint_line(start: Vector2, end: Vector2, line_width: int, element_name: String) -> void:
	if start.distance_to(end) > line_width / 2.0:
		var point: Vector2 = start
		var move_dir: Vector2 = (end - start).normalized()
		var step: float = line_width / 4.0
		while point.distance_to(end) > step:
			paint_circle(point, line_width / 2, element_name)
			point += move_dir * step
	paint_circle(end, line_width / 2, element_name)

func paint_circle(center: Vector2, radius: float, element_name: String) -> void:
	var center_row: int = center.y
	var center_col: int = center.x
	if not sim.in_bounds(center_row, center_col):
		return
	for row in range(-radius, radius + 1):
		for col in range(-radius, radius + 1):
			if row * row + col * col < radius * radius:
				if not sim.in_bounds(row + center_row, col + center_col):
					continue
				sim.set_element(row + center_row, col + center_col, element_name)