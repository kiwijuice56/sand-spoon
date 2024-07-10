class_name Simulation extends TextureRect

## Draw chunk borders and other debug details.
@export var debug_draw: bool
@export var debug_heat_gradient: GradientTexture1D

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

# Stores the ID of each cell of the simulation as a flat array.
var cell_id: PackedByteArray

# Stores the data of each cell of the simulation as a flat array.
var cell_data: PackedInt32Array

# Stores the amount of alive cells within each chunk as a flat array.
var alive_count: PackedByteArray

# Stores 1 if a chunk was updated between draw calls, otherwise 0.
var chunk_update: PackedByteArray

var chunk_temp: PackedByteArray
var chunk_temp_copy: PackedByteArray

# Output image of the simulation.
var image: Image

# World width and height in chunks.
var simulation_size_chunk: Vector2i

func _ready() -> void:
	randomize()
	assert(simulation_size.x % chunk_size == 0 and simulation_size.y % chunk_size == 0)
	_update_rect()
	
	for element in elements:
		element.initialize()
	
	name_id_map = {}
	for i in range(len(elements)):
		name_id_map[elements[i].unique_name] = i
		id_name_map.append(elements[i].unique_name)
	
	cell_id = []
	cell_id.resize(simulation_size.x * simulation_size.y)
	
	cell_data = []
	cell_data.resize(simulation_size.x * simulation_size.y)
	
	simulation_size_chunk.x = ceil(simulation_size.x / float(chunk_size))
	simulation_size_chunk.y = ceil(simulation_size.y / float(chunk_size))
	alive_count = []
	alive_count.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	
	chunk_update = []
	chunk_update.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	chunk_update.fill(1)
	
	chunk_temp = []
	chunk_temp.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	chunk_temp.fill(128)
	
	chunk_temp_copy = []
	chunk_temp_copy.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	chunk_temp_copy.fill(128)
	
	image = Image.create_empty(simulation_size.x, simulation_size.y, false, Image.FORMAT_RGBAF)
	
	for row in range(simulation_size.y):
		for col in range(simulation_size.x):
			set_element(row, col, "empty")

func _draw() -> void:
	if not debug_draw:
		return
	for chunk_row in range(simulation_size_chunk.y):
		for chunk_col in range(simulation_size_chunk.x):
			if alive_count[chunk_row * simulation_size_chunk.x + chunk_col] == 0:
				pass
			var rect: Rect2 = Rect2(
				chunk_col * chunk_size * simulation_scale, 
				chunk_row * chunk_size * simulation_scale, 
				chunk_size * simulation_scale, 
				chunk_size * simulation_scale)
			draw_rect(rect, debug_heat_gradient.gradient.sample(chunk_temp[chunk_row * simulation_size_chunk.x + chunk_col] / 255.0), false, 3)

func _process(_delta: float) -> void:
	for i in range(simulation_size_chunk.x * simulation_size_chunk.y - 1, -1, -1):
		if alive_count[i] == 0:
			chunk_temp_copy[i] = chunk_temp[i]
			continue
		var row_offset: int = i / simulation_size_chunk.x * chunk_size
		var col_offset: int = i % simulation_size_chunk.x * chunk_size
		var chunk_avg_temp: int = 0
		for j in range(chunk_size * chunk_size - 1, -1, -1):
			var row: int = j / chunk_size + row_offset
			var col: int = j % chunk_size + col_offset
			var element: Element = elements[cell_id[row * simulation_size.x + col]]
			var data: int = _get_cell_data(row, col)
			chunk_avg_temp += element.get_byte(data, 0)
			element.process(self, row, col, data)
		chunk_avg_temp /= chunk_size * chunk_size
		chunk_temp_copy[i] = chunk_avg_temp
	
	for i in range(simulation_size_chunk.x * simulation_size_chunk.y):
		chunk_temp[i] = (chunk_temp[i] + chunk_temp_copy[i]) / 2
	for row in range(simulation_size_chunk.y):
		for col in range(simulation_size_chunk.x):
			var avg_temp: int = _get_chunk_temp(row, col, 128) 
			avg_temp += _get_chunk_temp(row + 1, col, 128) 
			avg_temp += _get_chunk_temp(row - 1, col, 128)
			avg_temp += _get_chunk_temp(row, col + 1, 128)
			avg_temp += _get_chunk_temp(row, col - 1, 128)
			chunk_temp_copy[row * simulation_size_chunk.x + col] = (chunk_temp[row * simulation_size_chunk.x + col] + avg_temp / 5) / 2
	for i in range(len(chunk_temp)):
		chunk_temp[i] = chunk_temp_copy[i]
	
	draw_cells()
	if debug_draw:
		queue_redraw()

func _update_rect() -> void:
	custom_minimum_size = simulation_size * simulation_scale

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

func _get_cell_data(row: int, col: int) -> int:
	return cell_data[row * simulation_size.x + col]

func _set_cell_data(row: int, col: int, data: int, update_color: bool = true) -> void:
	cell_data[row * simulation_size.x + col] = data
	if update_color:
		chunk_update[row / chunk_size * simulation_size_chunk.x + col / chunk_size] = 1

func _get_chunk_temp(row: int, col: int, default: int) -> int:
	if row < 0 or col < 0 or row >= simulation_size_chunk.y or col >= simulation_size_chunk.x: 
		return default
	return chunk_temp[row * simulation_size_chunk.x + col]

## Returns the Element resource at row, col.
func get_element_resource(row: int, col: int) -> Element:
	return elements[_get_cell_id(row, col)]

## Returns the element at row, col.
func get_element(row: int, col: int) -> String:
	return id_name_map[_get_cell_id(row, col)]

## Returns the cell data at row, col.
func get_data(row: int, col: int) -> int:
	return _get_cell_data(row, col)

func get_chunk_temp(row: int, col: int) -> int:
	if in_bounds(row + 1, col) and Simulation.fast_randf() < 0.5:
		row += 1
	if in_bounds(row, col + 1) and Simulation.fast_randf() < 0.5:
		col += 1
		
	return chunk_temp[row / chunk_size * simulation_size_chunk.x + col / chunk_size] 

## Updates the element at row, col.
func set_element(row: int, col: int, element_name: String) -> void:
	_set_cell_id(row, col, name_id_map[element_name])
	_set_cell_data(row, col, elements[_get_cell_id(row, col)].get_default_data(self, row, col))

## Updates the cell data at row, col.
func set_data(row: int, col: int, data: int, update_color: bool = true) -> void:
	_set_cell_data(row, col, data, update_color)

## Returns whether the location row, col is in bounds.
func in_bounds(row: int, col: int) -> bool:
	return row < simulation_size.y and col < simulation_size.x and row >= 0 and col >= 0

## Swap the element at row_1, col_1 with the element at row_2, col2.
## Assumes both cells are in bounds.
func swap(row_1: int, col_1: int, row_2: int, col_2: int) -> void:
	var temp: int = _get_cell_id(row_1, col_1)
	var temp_data: int = _get_cell_data(row_1, col_1)
	_set_cell_id(row_1, col_1, _get_cell_id(row_2, col_2))
	_set_cell_data(row_1, col_1, _get_cell_data(row_2, col_2))
	_set_cell_id(row_2, col_2, temp)
	_set_cell_data(row_2, col_2, temp_data)

## Updates modified chunks in the image and texture. 
func draw_cells() -> void:
	for i in range(simulation_size_chunk.x * simulation_size_chunk.y):
		if chunk_update[i] == 0:
			continue
		for j in range(0, chunk_size * chunk_size):
			var row: int = j / chunk_size + i / simulation_size_chunk.x * chunk_size
			var col: int = j % chunk_size + i % simulation_size_chunk.x * chunk_size
			image.set_pixel(col, row, elements[cell_id[row * simulation_size.x + col]].get_color(self, row, col, _get_cell_data(row, col)))
	chunk_update.fill(0)
	texture.set_image(image)

## A faster implementation of randf(), not yet implemented.
static func fast_randf() -> float:
	return randf()
