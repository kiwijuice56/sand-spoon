class_name Prompter extends HTTPRequest

@export var sim: Simulation
@export var start_button: Button
@export var element_name_edit: LineEdit
@export var status_label: StatusLabel
@export var sound_transition_time: float = 0.3

var custom_elements: Array[Element]
var sound_tween: Tween

signal element_created
signal properties_received(properties: Dictionary)

func _ready() -> void:
	start_button.pressed.connect(_on_button_pressed)
	request_completed.connect(_on_request_completed)
	_enable_button()

func _on_button_pressed() -> void:
	_disable_button()
	prompt(element_name_edit.text)

func _disable_button() -> void:
	if is_instance_valid(sound_tween):
		sound_tween.stop()
	sound_tween = get_tree().create_tween()
	sound_tween.tween_property(%ThinkingPlayer, "volume_db", -8, sound_transition_time)
	
	
	start_button.disabled = true
	start_button.text = "working..."

func _enable_button() -> void:
	if is_instance_valid(sound_tween):
		sound_tween.stop()
	sound_tween = get_tree().create_tween()
	sound_tween.tween_property(%ThinkingPlayer, "volume_db", -64, sound_transition_time)
	
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
	status_label.show_text("STATUS: querying server, please wait...", StatusLabel.TextType.WORKING)
	
	if element_name in sim.name_id_map:
		status_label.show_text("ERROR: element name already exists.", StatusLabel.TextType.ERROR)
		_enable_button()
		return
	
	var prompt_name: String = ""
	for c in element_name:
		if c.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789":
			prompt_name += c
		if c == " ":
			prompt_name += "_"
	
	if len(prompt_name) == 0:
		status_label.show_text("ERROR: enter a valid element name.", StatusLabel.TextType.ERROR)
		_enable_button()
		return
	
	request("https://122412240.xyz/?element_name=" + prompt_name)
	var properties = await properties_received
	
	if not properties:
		status_label.show_text("ERROR: connection failed. may be rate limited, please try again later.", StatusLabel.TextType.ERROR)
		_enable_button()
		return
	
	if "warning" in properties:
		status_label.show_text("ERROR: query breaks content policy. be nice!", StatusLabel.TextType.ERROR)
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
			element.decay_proportion = randf_range(0.1, 0.5)
			element.decay_transformation = "empty"
		"electricity":
			element = Lightning.new()
		"explosive":
			element = Solid.new()
	
	element.unique_name = element_name
	
	element.ui_color = properties["color_0"]
	
	element.pixel_color = GradientTexture1D.new()
	element.pixel_color.gradient = Gradient.new()
	
	# Add HDR glow to hot elements
	if properties["temperature"] > 1000:
		element.pixel_color.use_hdr = true
		element.pixel_color.gradient.set_color(0, Color(properties["color_0"]) * 2)
		element.pixel_color.gradient.set_color(0, Color(properties["color_1"]) * 2)
	else:
		element.pixel_color.gradient.set_color(0, properties["color_0"])
		element.pixel_color.gradient.set_color(1, properties["color_1"])
	
	element.initial_temperature = properties["temperature"]
	
	sim.add_element(element, false, true)
	ResourceSaver.save(element, "user://" + str(randi() % 999999) + prompt_name + ".tres")
	element_created.emit()
	
	status_label.show_text("SUCCESS: element created!", StatusLabel.TextType.SUCCESS)
	
	_enable_button()
