class_name Imager extends Node

@export var sim: Simulation
@export var paint_element: Element
@export var palette: Array[Color]
@export var background_color: Color
@export var random_variation: float = 0.2

var palette_map: Dictionary
var color_cache: Dictionary

func _ready() -> void:
	get_viewport().files_dropped.connect(_on_files_dropped)
	create_elements(paint_element)

func _on_files_dropped(files: PackedStringArray) -> void:
	var file: String = files[0]
	var image: Image = Image.load_from_file(file)
	if image == null:
		return
	paint_image(image)

func create_elements(template_element: Element) -> void:
	palette.append(background_color)
	for i in len(palette):
		var color: Color = palette[i]
		var color_x: Color = color
		color_x.s *= 1.15
		var new_element: Element = template_element.duplicate()
		var new_gradient: Gradient = Gradient.new()
		new_gradient.set_color(0, color_x.darkened(random_variation))
		new_gradient.set_color(1, color_x.lightened(random_variation))
		new_element.pixel_color = GradientTexture1D.new()
		new_element.pixel_color.gradient = new_gradient
		new_element.unique_name = "_internal_palette_" + str(i)
		new_element.hidden = true
		
		sim.add_element(new_element)
		
		palette_map[color] = new_element

func paint_image(image: Image) -> void:
	color_cache = {}
	
	var new_size: Vector2i = Vector2i()
	var scale_x: float = image.get_width() / float(sim.simulation_size.x)
	var scale_y: float = image.get_height() / float(sim.simulation_size.y)
	if scale_x > scale_y:
		new_size = Vector2i(sim.simulation_size.x, int(image.get_height() / scale_x))
	else:
		new_size = Vector2i(int(image.get_width() / scale_y), sim.simulation_size.y)
	
	var x_offset: int = 0
	var y_offset: int = 0
	if scale_x > scale_y:
		y_offset = (sim.simulation_size.y - new_size.y) / 2
	else:
		x_offset = (sim.simulation_size.x - new_size.x) / 2
	
	for y in sim.simulation_size.y:
		for x in sim.simulation_size.x:
			var px_paint_element: Element
			if scale_x > scale_y and (y < y_offset or y > y_offset + new_size.y):
				px_paint_element = palette_map[background_color]
			elif scale_x <= scale_y and (x < x_offset or x > x_offset + new_size.x):
				px_paint_element = palette_map[background_color]
			else:
				var uv: Vector2 = Vector2(x - x_offset, y - y_offset) / Vector2(new_size.x, new_size.y)
				var px_coord: Vector2i = Vector2i(uv * Vector2(image.get_width() - 1, image.get_height() - 1))
				px_paint_element = get_closest_element(image.get_pixel(px_coord.x, px_coord.y))
			# A bit risky, but bypass helper methods to prevent triggering unwanted particle updates
			sim.cell_id[y * sim.simulation_size.x + x] = sim.name_id_map[px_paint_element.unique_name]
			sim.cell_data[y * sim.simulation_size.x + x] = px_paint_element.get_default_data(sim, y, x)
	sim.chunk_update.fill(1)
	sim.alive_count.fill(sim.chunk_size ** 2)

func get_color_difference(a: Color, b: Color) -> float:
	# Treat alpha as "darkness" to prevent weird artifacts with transparent backgrounds.
	b *= b.a
	return (a.h - b.h) * (a.h - b.h) + (a.s - b.s) * (a.s - b.s) + (a.v - b.v) * (a.v - b.v)

func get_closest_element(original: Color) -> Element:
	if original in color_cache:
		return color_cache[original]
	var min_dif: float = INF
	var closest_element: Element
	for color in palette_map:
		var dif: float =  get_color_difference(color, original)
		if dif < min_dif:
			closest_element = palette_map[color]
			min_dif = dif
	color_cache[original] = closest_element
	return closest_element
