class_name Imager extends Node

@export var sim: Simulation
@export var paint_element: Element
@export var palette: Array[Color]

var palette_map: Dictionary

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
	# Other elements types not yet supported
	assert(template_element is Fluid or template_element is Solid)
	for i in len(palette):
		var color: Color = palette[i]
		var new_element: Element = template_element.duplicate()
		var new_gradient: Gradient = Gradient.new()
		new_gradient.set_color(0, color.darkened(0.1))
		new_gradient.set_color(1, color.lightened(0.1))
		new_element.color_gradient = GradientTexture1D.new()
		new_element.color_gradient.gradient = new_gradient
		new_element.unique_name = "_internal_palette_" + str(i)
		
		sim.add_element(new_element)
		
		palette_map[color] = new_element

func paint_image(image: Image) -> void:
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
		y_offset = sim.simulation_size.y / 2 - new_size.y / 2
	else:
		x_offset = sim.simulation_size.x / 2 - new_size.x / 2
	
	for y in new_size.y:
		for x in new_size.x:
			var uv: Vector2 = Vector2(x, y) / Vector2(new_size.x, new_size.y)
			var px_coord: Vector2i = Vector2i(uv * Vector2(image.get_width(), image.get_height()))
			var element: Element = get_closest_element(image.get_pixel(px_coord.x, px_coord.y))
			sim.paint_element(y + y_offset, x + x_offset, element.unique_name)

func get_color_difference(a: Color, b: Color) -> float:
	return pow(a.h - b.h, 2) + pow(a.s - b.s, 2) + pow(a.v - b.v, 2)

func get_closest_element(original: Color) -> Element:
	var min_dif: float = INF
	var closest_element: Element
	for color in palette_map:
		var dif: float =  get_color_difference(color, original)
		if dif < min_dif:
			closest_element = palette_map[color]
			min_dif = dif
	return closest_element
