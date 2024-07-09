class_name Simulation extends TextureRect

@export var width: int
@export var height: int  
var data: Array[Particle]

func _ready() -> void:
	data = []
	data.resize(width * height)
	for i in range(len(data)):
		if randf() < 0.1:
			data[i] = Sand.new()
		else:
			data[i] = Empty.new()

func _draw() -> void:
	for i in range(width * height):
		var row: int = i / width
		var col: int = i % width
		
		draw_rect(Rect2(col, row, 1, 1), data[i].color)

func _input(_event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_position: Vector2 = get_viewport().get_mouse_position() / scale
		var row: int = int(mouse_position.y)
		var col: int = int(mouse_position.x)
		paint_circle(row, col, 4, Sand.new())

func _process(_delta: float) -> void:
	for i in range(width * height - 1, -1, -1):
		var row: int = i / width
		var col: int = i % width
		
		data[i].process(self, row, col)
	queue_redraw()

func paint_circle(center_row: int, center_col: int, radius: float, type: Particle) -> void:
	if not in_bounds(center_row, center_col):
		return
	for row in range(-radius, radius + 1):
		for col in range(-radius, radius + 1):
			if row * row + col * col < radius * radius:
				set_particle(row + center_row, col + center_col, type.duplicate())

func get_particle(row: int, col: int) -> Particle:
	return data[row * width + col]

func set_particle(row: int, col: int, particle: Particle) -> void:
	data[row * width + col] = particle

func in_bounds(row: int, col: int) -> bool:
	return row >= 0 and col >= 0 and row < height and col < width

func swap(row1: int, col1: int, row2: int, col2: int) -> void:
	var temp: Particle = get_particle(row1, col1)
	set_particle(row1, col1, get_particle(row2, col2))
	set_particle(row2, col2, temp)

func rand() -> float:
	return randf()
