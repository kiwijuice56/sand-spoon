class_name Prompter extends HTTPRequest

@export var sim: Simulation
@export var start_button: Button
@export var element_name_edit: LineEdit

signal properties_received(properties: Dictionary)

func _ready() -> void:
	start_button.pressed.connect(_on_button_pressed)
	request_completed.connect(_on_request_completed)
	_enable_button()

func _on_button_pressed() -> void:
	_disable_button()
	prompt(element_name_edit.text)

func _disable_button() -> void:
	start_button.disabled = true
	start_button.text = "working..."

func _enable_button() -> void:
	start_button.disabled = false
	start_button.text = "imagine"

func _on_request_completed(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not result == RESULT_SUCCESS:
		properties_received.emit(null)
		return
	
	var json: Variant = JSON.parse_string(body.get_string_from_utf8())
	print(json)
	
	if not json:
		properties_received.emit(null)
		return
	
	properties_received.emit(json as Dictionary)

func prompt(element_name: String) -> void:
	var prompt_name: String = element_name.replace(" ", "_")
	if len(prompt_name) == 0:
		_enable_button()
		return
	
	request("https://122412240.xyz/?element_name=" + prompt_name)
	var properties: Dictionary = await properties_received
	
	if not properties or "warning" in properties:
		_enable_button()
		return
	
	var element: Element
	match properties["state"]:
		"liquid":
			element = Fluid.new()
			element.gravity_down = true
			element.viscosity = properties["viscosity"]
			# The API tends to send repeated values, so it helps to have some randomness.
			element.density = randf_range(0.75, 1.25) * properties["density"]
		"gas":
			element = Fluid.new()
			element.gravity_down = false
			element.density = randf_range(0.75, 1.25) * properties["density"]
		"rigid_solid":
			element = Solid.new()
		"powdery_solid":
			element = Powder.new()
		"metal":
			element = Metal.new()
		"creature":
			element = Critter.new()
		"microbe":
			element = Bacteria.new()
			element.home_material = "empty"
		"laser":
			element = Laser.new()
		"electricity":
			element = Lightning.new()
		"explosive":
			element = Solid.new()
	
	element.unique_name = element_name
	
	element.ui_color = properties["color_0"]
	
	element.pixel_color = GradientTexture1D.new()
	element.pixel_color.gradient = Gradient.new()
	element.pixel_color.gradient.set_color(0, properties["color_0"])
	element.pixel_color.gradient.set_color(1, properties["color_1"])
	
	element.initial_temperature = properties["temperature"]
	
	sim.add_element(element, false, true)
	
	_enable_button()
