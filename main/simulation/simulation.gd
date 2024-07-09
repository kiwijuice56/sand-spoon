class_name Simulation extends TextureRect

## Draw chunk borders and other debug details.
@export var debug_draw: bool

## World width and height.
@export var simulation_size: Vector2i

## Canvas scaling factor.
@export var simulation_scale: int

## Width/height of square chunks that separate the world.
@export var chunk_size: int

## All elements available to the simulation. Add your Element resources here.
@export var elements: Array[Element]

# Maps Element unique_names to their int IDs.
static var name_id_map: Dictionary

# Maps int IDs to Element unique_names.
static var id_name_map: PackedStringArray

# Stores the ID within each cell of the simulation as a flat array.
var cell_id: PackedByteArray

# Stores the amount of alive cells within each chunk as a flat array.
var alive_count: PackedByteArray

# Stores 1 if a chunk was updated between draw calls, otherwise 0.
var chunk_update: PackedByteArray

# Output image of the simulation.
var image: Image

# World width and height in chunks.
var simulation_size_chunk: Vector2i

func _ready() -> void:
	_update_rect()
	
	assert(simulation_size.x % chunk_size == 0 and simulation_size.y % chunk_size == 0)
	
	name_id_map = {}
	for i in range(len(elements)):
		name_id_map[elements[i].unique_name] = i
		id_name_map.append(elements[i].unique_name)
	
	cell_id = []
	cell_id.resize(simulation_size.x * simulation_size.y)
	
	simulation_size_chunk.x = ceil(simulation_size.x / float(chunk_size))
	simulation_size_chunk.y = ceil(simulation_size.y / float(chunk_size))
	alive_count = []
	alive_count.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	
	chunk_update = []
	chunk_update.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	chunk_update.fill(1)
	
	image = Image.create_empty(simulation_size.x, simulation_size.y, false, Image.FORMAT_RGBA8)

func _draw() -> void:
	if not debug_draw:
		return
	for chunk_row in range(simulation_size_chunk.y):
		for chunk_col in range(simulation_size_chunk.x):
			if alive_count[chunk_row * simulation_size_chunk.x + chunk_col] == 0:
				continue
			var rect: Rect2 = Rect2(
				chunk_col * chunk_size * simulation_scale, 
				chunk_row * chunk_size * simulation_scale, 
				chunk_size * simulation_scale, 
				chunk_size * simulation_scale)
			draw_rect(rect, Color.RED.lightened(alive_count[chunk_row * simulation_size_chunk.x + chunk_col] / float(chunk_size * chunk_size)), false)

func _process(_delta: float) -> void:
	for i in range(simulation_size_chunk.x * simulation_size_chunk.y):
		if alive_count[i] == 0:
			continue
		for j in range(chunk_size * chunk_size - 1, -1, -1):
			var row: int = j / chunk_size + i / simulation_size_chunk.x * chunk_size
			var col: int = j % chunk_size + i % simulation_size_chunk.x * chunk_size
			elements[cell_id[row * simulation_size.x + col]].process(self, row, col)
	draw_cells()
	if debug_draw:
		queue_redraw()

func _update_rect() -> void:
	size = simulation_size * simulation_scale

func _get_cell_id(row: int, col: int) -> int:
	return cell_id[row * simulation_size.x + col]

func _set_cell_id(row: int, col: int, element_id: int) -> void:
	var old_id: int = cell_id[row * simulation_size.x + col]
	cell_id[row * simulation_size.x + col] = element_id
	chunk_update[row / chunk_size * simulation_size_chunk.x + col / chunk_size] = 1
	if old_id == 0 and element_id > 0:
		alive_count[row / chunk_size * simulation_size_chunk.x + col / chunk_size] += 1
	elif old_id > 0 and element_id == 0:
		alive_count[row / chunk_size * simulation_size_chunk.x + col / chunk_size] -= 1

## Returns the Element resource with the given element_name.
func get_element_resource(element_name: String) -> Element:
	return elements[name_id_map[element_name]]

## Returns the element at row, col.
func get_element(row: int, col: int) -> String:
	return id_name_map[_get_cell_id(row, col)]

## Updates the element at row, col.
func set_element(row: int, col: int, element_name: String) -> void:
	_set_cell_id(row, col, name_id_map[element_name])

## Returns whether the location row, col is in bounds.
func in_bounds(row: int, col: int) -> bool:
	return row >= 0 and col >= 0 and row < simulation_size.y and col < simulation_size.x

## Swap the element at row_1, col_1 with the element at row_2, col2.
## Assumes both cells are in bounds.
func swap(row_1: int, col_1: int, row_2: int, col_2: int) -> void:
	var temp: int = _get_cell_id(row_1, col_1)
	_set_cell_id(row_1, col_1, _get_cell_id(row_2, col_2))
	_set_cell_id(row_2, col_2, temp)

## Updates modified chunks in the image and texture. 
func draw_cells() -> void:
	for i in range(simulation_size_chunk.x * simulation_size_chunk.y):
		if chunk_update[i] == 0:
			continue
		for j in range(0, chunk_size * chunk_size):
			var row: int = j / chunk_size + i / simulation_size_chunk.x * chunk_size
			var col: int = j % chunk_size + i % simulation_size_chunk.x * chunk_size
			
			image.set_pixel(col, row, elements[cell_id[row * simulation_size.x + col]].get_color(self, row, col))
	chunk_update.fill(0)
	texture.set_image(image)

## A faster implementation of randf(), not yet implemented.
static func fast_randf() -> float:
	return randf()
