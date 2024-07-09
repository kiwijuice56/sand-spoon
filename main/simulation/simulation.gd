class_name Simulation extends TextureRect

@export var debug_draw: bool
@export var simulation_size: Vector2
@export var chunk_size: int
@export var elements: Array[Element]

static var name_id_map: Dictionary
static var id_name_map: PackedStringArray

var cell_id: PackedByteArray
var chunk_count: PackedByteArray
var image: Image

var width: int
var height: int
var chunk_width: int
var chunk_height: int

func _ready() -> void:
	width = int(simulation_size.x)
	height = int(simulation_size.y)
	
	assert(width % chunk_size == 0 and height % chunk_size == 0)
	
	name_id_map = {}
	for i in range(len(elements)):
		name_id_map[elements[i].unique_name] = i
		id_name_map.append(elements[i].unique_name)
	
	cell_id = []
	cell_id.resize(width * height)
	
	chunk_width = ceil(width / float(chunk_size))
	chunk_height = ceil(height / float(chunk_size))
	chunk_count = []
	chunk_count.resize(chunk_width * chunk_height)
	
	image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)

func _draw() -> void:
	if not debug_draw:
		return
	for chunk_row in range(chunk_height):
		for chunk_col in range(chunk_width):
			if chunk_count[chunk_row * chunk_width + chunk_col] == 0:
				continue
			var rect: Rect2 = Rect2(chunk_col * chunk_size, chunk_row * chunk_size, chunk_size, chunk_size)
			draw_rect(rect, Color.RED, false)

func _process(_delta: float) -> void:
	for i in range(chunk_width * chunk_height):
		if chunk_count[i] == 0:
			continue
		for j in range(chunk_size * chunk_size - 1, -1, -1):
			var row: int = j / chunk_size + i / chunk_width * chunk_size
			var col: int = j % chunk_size + i % chunk_width * chunk_size
			elements[cell_id[row * width + col]].process(self, row, col)
	draw_cells()
	if debug_draw:
		queue_redraw()

func _get_cell_id(row: int, col: int) -> int:
	return cell_id[row * width + col]

func _set_cell_id(row: int, col: int, element_id: int) -> void:
	var old_id: int = cell_id[row * width + col]
	cell_id[row * width + col] = element_id
	if old_id == 0 and element_id > 0:
		chunk_count[row / chunk_size * chunk_width + col / chunk_size] += 1
	elif old_id > 0 and element_id == 0:
		chunk_count[row / chunk_size * chunk_width + col / chunk_size] -= 1

func get_element_resource(element_name: String) -> Element:
	return elements[name_id_map[element_name]]

func get_element(row: int, col: int) -> String:
	return id_name_map[_get_cell_id(row, col)]

func set_element(row: int, col: int, element_name: String) -> void:
	_set_cell_id(row, col, name_id_map[element_name])

func in_bounds(row: int, col: int) -> bool:
	return row >= 0 and col >= 0 and row < height and col < width

func swap(row_1: int, col_1: int, row_2: int, col_2: int) -> void:
	var temp: int = _get_cell_id(row_1, col_1)
	_set_cell_id(row_1, col_1, _get_cell_id(row_2, col_2))
	_set_cell_id(row_2, col_2, temp)

func draw_cells() -> void:
	for i in range(width * height):
		var row: int = i / width
		var col: int = i % width
		
		image.set_pixel(col, row, elements[cell_id[i]].get_color(self, row, col))
	
	texture.set_image(image)

static func fast_randf() -> float:
	return randf()
