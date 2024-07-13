class_name Simulation extends TextureRect

@export var simulation_size: Vector2i ## World width and height.
@export var simulation_scale: int ## Canvas scaling factor.

## All elements available to the simulation. Add your Element resources here. 
## First slot MUST be the Empty element.
@export var elements: Array[Element]

@export_group("Advanced")
@export var chunk_size: int ## Width/height of square chunks that separate the world.
@export var random_awaken_chance: float = 0.68 ## The chance that sleeping chunks will re-awaken for a frame.

@export_group("Debug")
@export var debug_draw: bool ## Draw chunk borders and temperature.
@export var debug_heat_gradient: GradientTexture1D

static var name_id_map: Dictionary # Maps Element unique_names to their int IDs.
static var id_name_map: PackedStringArray # Maps int IDs to Element unique_names.

var cell_id: PackedByteArray # Stores the ID of each cell of the simulation as a flat array.
var cell_data: PackedInt32Array # Stores the data of each cell of the simulation as a flat array.

var alive_count: PackedByteArray # Stores the amount of non-empty particles within each chunk as a flat array.
var awake_chunk: PackedByteArray # Stores whether each chunk awake alive (containing moving/changing particles) as a flat array of as true/false.
var should_awake_chunk: PackedByteArray # Stores whether each chunk should be awake on the next frame as a flat array of true/false.
var chunk_update: PackedByteArray # Stores whether each chunk has had any visual updates within this frame as a flat array of true/false.

var chunk_temp: PackedInt32Array # Stores the temperature of the chunk.
var chunk_temp_copy: PackedInt32Array # Stores intermediate chunk temperature calculations.

var image: Image # Output image of the simulation.

var simulation_size_chunk: Vector2i # World width and height in chunks.

var idefault_temperature: int # Default temperature of the air (defined by Empty).

# Multitthreading state variables
var should_exit: bool = false
var sem: Semaphore
var mutex: Mutex
var threads: Array[Thread]
var thread_counter: int
var thread_counter_done: int
var global_row_offset: int 
var frame_count: int = 0

func _ready() -> void:
	randomize()
	assert(simulation_size.x % chunk_size == 0 and simulation_size.y % chunk_size == 0)
	_update_rect()
	
	# Set default temperature to the temperature of Empty.
	for element in elements:
		element.initialize()
		if element is Empty:
			idefault_temperature = element.iinitial_temperature
	
	# Initialize name/element mapping.
	name_id_map = {}
	for i in range(len(elements)):
		name_id_map[elements[i].unique_name] = i
		id_name_map.append(elements[i].unique_name)
	
	cell_id = []
	cell_data = []
	alive_count = []
	awake_chunk = []
	should_awake_chunk = []
	chunk_update = []
	chunk_temp = []
	chunk_temp_copy = []
	cell_id.resize(simulation_size.x * simulation_size.y)
	
	
	cell_data.resize(simulation_size.x * simulation_size.y)
	simulation_size_chunk.x = ceil(simulation_size.x / float(chunk_size))
	simulation_size_chunk.y = ceil(simulation_size.y / float(chunk_size))
	alive_count.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	awake_chunk.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	should_awake_chunk.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	chunk_update.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	
	chunk_temp.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	chunk_temp.fill(idefault_temperature)
	chunk_temp_copy.resize(simulation_size_chunk.x * simulation_size_chunk.y)
	chunk_temp_copy.fill(idefault_temperature)
	
	chunk_update.fill(1)
	
	image = Image.create_empty(simulation_size.x, simulation_size.y, false, Image.FORMAT_RGBAF)
	
	for row in range(simulation_size.y):
		for col in range(simulation_size.x):
			set_element(row, col, "empty")
	
	# Start threads.
	sem = Semaphore.new()
	mutex = Mutex.new()
	for _i in OS.get_processor_count():
		var thread: Thread = Thread.new()
		threads.append(thread)
		thread.start(_thread_process)

## Debug drawing method.
func _draw() -> void:
	if not debug_draw:
		return
	for chunk_row in simulation_size_chunk.y:
		for chunk_col in simulation_size_chunk.x:
			if awake_chunk[chunk_row * simulation_size_chunk.x + chunk_col] == 0:
				continue
			var rect: Rect2 = Rect2(
				chunk_col * chunk_size * simulation_scale, 
				chunk_row * chunk_size * simulation_scale, 
				chunk_size * simulation_scale, 
				chunk_size * simulation_scale)
			draw_rect(rect, debug_heat_gradient.gradient.sample(chunk_temp[chunk_row * simulation_size_chunk.x + chunk_col] / 65535.0), false, 1)

## Advances the simulation.
func _process(_delta: float) -> void:
	should_awake_chunk.fill(0)
	global_row_offset =  randi_range(-1, 1)
	
	# Simulate the entire grid by giving threads a row of chunks to process.
	# Alternate between odd/even rows in order to prevent access errors.
	thread_counter = 0 # Odd
	thread_counter_done = 0
	for i in simulation_size_chunk.y / 2:
		sem.post()
	while thread_counter_done != simulation_size_chunk.y / 2:
		pass
	
	thread_counter = 1 # Even
	thread_counter_done = 0
	for i in simulation_size_chunk.y / 2:
		sem.post()
	while thread_counter_done != simulation_size_chunk.y / 2:
		pass
	
	for i in len(awake_chunk):
		awake_chunk[i] = should_awake_chunk[i]
	
	# Temperature diffusion.
	for i in simulation_size_chunk.x * simulation_size_chunk.y:
		chunk_temp[i] = (chunk_temp[i] + chunk_temp_copy[i]) >> 1
	for i in simulation_size_chunk.x * simulation_size_chunk.y:
		var row: int = i / simulation_size_chunk.x
		var col: int = i % simulation_size_chunk.x
		var avg_temp: int = _get_chunk_temp(row, col) + _get_chunk_temp(row + 1, col) + _get_chunk_temp(row - 1, col) + _get_chunk_temp(row, col + 1) + _get_chunk_temp(row, col - 1)
		chunk_temp_copy[i] = (chunk_temp[i] + avg_temp / 5) >> 1
	for i in len(chunk_temp):
		chunk_temp[i] = chunk_temp_copy[i]
	
	draw_cells()
	if debug_draw:
		queue_redraw()
	
	frame_count += 1

func _exit_tree():
	should_exit = true
	for i in simulation_size_chunk.y:
		sem.post()
	for thread in threads:
		thread.wait_to_finish()

func _thread_process() -> void:
	while true:
		sem.wait()
		if should_exit: 
			break
		
		var chunk_row: int
		var extra_offset: int
		mutex.lock()
		extra_offset = global_row_offset # Store an extra row offset to reduce chunk seams.
		chunk_row = thread_counter
		thread_counter += 2
		mutex.unlock()
		
		var particle_order: Array[int] = []
		for i in chunk_size * chunk_size:
			particle_order.append(i)
		
		for i in range(chunk_row * simulation_size_chunk.x, (chunk_row + 1) * simulation_size_chunk.x):
			chunk_temp_copy[i] = chunk_temp[i]
			if alive_count[i] == 0 or (awake_chunk[i] == 0 and fast_randf() > random_awaken_chance):
				continue
			var row_offset: int = i / simulation_size_chunk.x * chunk_size + extra_offset
			var col_offset: int = i % simulation_size_chunk.x * chunk_size
			var chunk_avg_temp: int = 0
			var processed: int = 0
			particle_order.shuffle()
			for j in particle_order:
				var row: int = j / chunk_size + row_offset 
				if row < 0:
					continue
				if row >= simulation_size.y:
					continue
				processed += 1
				var col: int = j % chunk_size + col_offset
				var data: int = get_data(row, col)
				chunk_avg_temp += Element.get_temperature(data)
				elements[cell_id[row * simulation_size.x + col]].process(self, row, col, data)
			if processed > 0:
				chunk_temp_copy[i] = chunk_avg_temp / processed
		
		mutex.lock()
		thread_counter_done += 1
		mutex.unlock()

func _update_rect() -> void:
	custom_minimum_size = simulation_size * simulation_scale

func _get_cell_id(row: int, col: int) -> int:
	return cell_id[row * simulation_size.x + col]

func _set_cell_id(row: int, col: int, element_id: int) -> void:
	_waken_chunk(row, col)
	var old_id: int = cell_id[row * simulation_size.x + col]
	cell_id[row * simulation_size.x + col] = element_id
	chunk_update[_get_chunk_index(row, col)] = 1
	if old_id == 0 and element_id > 0:
		alive_count[_get_chunk_index(row, col)] += 1
	elif old_id > 0 and element_id == 0:
		alive_count[_get_chunk_index(row, col)] -= 1

func _set_cell_data(row: int, col: int, data: int, update_color: bool = true) -> void:
	cell_data[row * simulation_size.x + col] = data
	if update_color:
		chunk_update[_get_chunk_index(row, col)] = 1

func _get_chunk_temp(row: int, col: int, default: int = idefault_temperature) -> int:
	if row < 0 or col < 0 or row >= simulation_size_chunk.y or col >= simulation_size_chunk.x: 
		return default
	return chunk_temp[row * simulation_size_chunk.x + col]

func _get_chunk_index(row: int, col: int) -> int:
	return row / chunk_size * simulation_size_chunk.x + col / chunk_size

func _waken_chunk(row: int, col: int) -> void:
	should_awake_chunk[_get_chunk_index(row, col)] = 1
	var chunk_row: int = row % chunk_size
	var chunk_col: int = col % chunk_size
	
	if row > 0 and chunk_row == 0:
		should_awake_chunk[_get_chunk_index(row - 1, col)] = 1
	if row < simulation_size.y - 1 and chunk_row == chunk_size - 1:
		should_awake_chunk[_get_chunk_index(row + 1, col)] = 1
	if col > 0 and chunk_col == 0:
		should_awake_chunk[_get_chunk_index(row, col - 1)] = 1
	if col < simulation_size.x - 1 and chunk_col == chunk_size - 1:
		should_awake_chunk[_get_chunk_index(row, col + 1)] = 1
	#if row >= chunk_size:
		#should_awake_chunk[_get_chunk_index(row - chunk_size, col)] = 1
	#if row < simulation_size.y - chunk_size:
		#should_awake_chunk[_get_chunk_index(row + chunk_size, col)] = 1
	#if col >= chunk_size:
		#should_awake_chunk[_get_chunk_index(row, col - chunk_size)] = 1
	#if col < simulation_size.x - chunk_size:
		#should_awake_chunk[_get_chunk_index(row, col + chunk_size)] = 1

## Returns the Element resource at row, col.
func get_element_resource(row: int, col: int) -> Element:
	return elements[_get_cell_id(row, col)]

## Returns the element name at row, col.
func get_element(row: int, col: int) -> String:
	return id_name_map[_get_cell_id(row, col)]

## Returns the cell data at row, col.
func get_data(row: int, col: int) -> int:
	return cell_data[row * simulation_size.x + col]

func get_element_resource_from_name(element_name: String) -> Element:
	return elements[name_id_map[element_name]]

func get_touch_count(row: int, col: int, element_name: String) -> int:
	var touches: int = 0
	var target_id: int = name_id_map[element_name]
	for i in 10:
		if i == 4: # Center
			continue
		var row_offset: int = i / 3 - 1
		var col_offset: int = i % 3 - 1
		if not in_bounds(row + row_offset, col + col_offset):
			continue
		if _get_cell_id(row + row_offset, col + col_offset) == target_id:
			touches += 1
	return touches

func get_chunk_temp(row: int, col: int) -> int:
	var original_row: int = row
	var original_col: int = col
	if Simulation.fast_randf() < 0.5:
		row += 1
	if Simulation.fast_randf() < 0.5:
		col += 1
	if Simulation.fast_randf() < 0.5:
		row -= 2
	if Simulation.fast_randf() < 0.5:
		col -= 2
	if not in_bounds(row, col):
		row = original_row
		col = original_col
	return chunk_temp[row / chunk_size * simulation_size_chunk.x + col / chunk_size] 

func paint_element(row: int, col: int, element_name: String) -> void:
	set_element(row, col, element_name)
	awake_chunk[_get_chunk_index(row, col)] = 1

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
	var temp_data: int = get_data(row_1, col_1)
	_set_cell_id(row_1, col_1, _get_cell_id(row_2, col_2))
	_set_cell_data(row_1, col_1, get_data(row_2, col_2))
	_set_cell_id(row_2, col_2, temp)
	_set_cell_data(row_2, col_2, temp_data)

## Updates modified chunks in the image and texture. 
func draw_cells() -> void:
	var updated: bool = false
	for i in simulation_size_chunk.x * simulation_size_chunk.y:
		if chunk_update[i] == 0:
			continue
		updated = true
		for j in chunk_size * chunk_size:
			var row: int = j / chunk_size + i / simulation_size_chunk.x * chunk_size
			var col: int = j % chunk_size + i % simulation_size_chunk.x * chunk_size
			image.set_pixel(col, row, elements[cell_id[row * simulation_size.x + col]].get_color(self, row, col, get_data(row, col)))
	if updated:
		chunk_update.fill(0)
		(texture as ImageTexture).set_image(image)

## A faster implementation of randf(), not yet implemented.
static func fast_randf() -> float:
	return randf()
