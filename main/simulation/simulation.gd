class_name Simulation extends TextureRect

@export var simulation_size: Vector2
@export var elements: Array[Element]

static var name_id_map: Dictionary
static var id_name_map: PackedStringArray

var cell_id: PackedByteArray
var width: int
var height: int

func _ready() -> void:
	width = int(simulation_size.x)
	height = int(simulation_size.y)
	
	name_id_map = {}
	for i in range(len(elements)):
		name_id_map[elements[i].unique_name] = i
		id_name_map.append(elements[i].unique_name)
	
	cell_id = []
	cell_id.resize(width * height)

func _draw() -> void:
	for i in range(width * height):
		var row: int = i / width
		var col: int = i % width
		
		draw_rect(Rect2(col, row, 1, 1), elements[cell_id[i]].get_color(self, row, col))

func _process(_delta: float) -> void:
	for i in range(width * height - 1, -1, -1):
		var row: int = i / width
		var col: int = i % width
		
		elements[cell_id[i]].process(self, row, col)
	queue_redraw()

func _get_cell_id(row: int, col: int) -> int:
	return cell_id[row * width + col]

func _set_cell_id(row: int, col: int, element_id: int) -> void:
	cell_id[row * width + col] = element_id

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

static func random() -> float:
	return randf()
