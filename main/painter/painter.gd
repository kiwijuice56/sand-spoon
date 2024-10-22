class_name Painter extends Node

@export var sim: Simulation
@export var selector: ElementSelector
@export var brush_size_selector: BrushSizeSelector
@export var clear_button: ClearButton

@export var brush_radius: int
@export var line_step: float = 0.5
@export var powder_skip_proportion: float = 0.25
@export var critter_skip_proportion: float = 0.25

var current_element: String = "sand"
var is_tapping: bool = false
var tap_start: Vector2i

func _ready() -> void:
	selector.element_selected.connect(_on_element_selected)
	brush_size_selector.size_selected.connect(_on_size_selected)
	clear_button.pressed.connect(_on_clear_pressed)
	await get_tree().get_root().ready

func _on_size_selected(size: int) -> void:
	brush_radius = size

func _on_element_selected(element: Element) -> void:
	current_element = element.unique_name

func _on_clear_pressed() -> void:
	for row in sim.simulation_size.y:
		for col in sim.simulation_size.x:
			paint_pixel(row, col, "empty")

func _process(_delta: float) -> void:
	if Input.is_action_pressed("tap"):
		var mouse_position: Vector2i = get_viewport().get_mouse_position() - sim.global_position
		mouse_position /= sim.simulation_scale
		if not is_tapping:
			tap_start = mouse_position
			is_tapping = true
		paint_line(tap_start, mouse_position, brush_radius, current_element)
		
		tap_start = mouse_position
	if Input.is_action_just_released("tap"):
		is_tapping = false

func paint_line(start: Vector2i, end: Vector2i, line_width: int, element_name: String) -> void:
	if start.distance_to(end) > line_width * line_step:
		var point: Vector2 = start
		var move_dir: Vector2 = Vector2(end - start).normalized()
		var step: float = line_width * line_step
		while point.distance_to(end) > step:
			paint_circle(point, line_width, element_name)
			point += move_dir * step
	paint_circle(end, line_width, element_name)

func paint_circle(center: Vector2i, radius: float, element_name: String) -> void:
	var center_row: int = center.y 
	var center_col: int = center.x 
	if not sim.in_bounds(center_row, center_col):
		return
	for row in range(-radius, radius + 1):
		for col in range(-radius, radius + 1):
			if row * row + col * col < radius * radius:
				paint_pixel(row + center_row, col + center_col, element_name)

func paint_pixel(row: int, col: int, element_name: String) -> void:
	if not sim.in_bounds(row, col):
		return
	var element_resource: Element = sim.get_element_resource_from_name(element_name)
	var old_element_resource: Element = sim.get_element_resource(row, col)
	if element_resource is Fluid and old_element_resource is Solid:
		return
	if element_resource is Powder and Simulation.fast_randf() < powder_skip_proportion:
		return
	if element_resource is Critter and Simulation.fast_randf() < critter_skip_proportion:
		return
	sim.paint_element(row, col, element_name)
