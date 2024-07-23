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

func _on_request_completed(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json: Variant = JSON.parse_string(body.get_string_from_utf8())
	print("result of query: ", json)
	
	if not json:
		properties_received.emit(null)
		return
	
	properties_received.emit(json as Dictionary)

func clean_prompt(original_prompt: String) -> String:
	var prompt_name: String = ""
	for c in original_prompt:
		if c.to_lower() in "abcdefghijklmnopqrstuvwxyz0123456789":
			prompt_name += c.to_lower()
		if c == " ":
			prompt_name += "_"
	return prompt_name

func realize_element(element_name: String, properties, hidden: bool = false) -> Element:
	var element: Element
	match properties["state"]:
		"liquid":
			element = Fluid.new()
			element.gravity_down = true
			element.viscosity = properties["viscosity"]
			# The API tends to send repeated values, so it helps to have some randomness.
			element.density = randf_range(0.75, 1.25) * properties["density"]
			
			# Add evaporation to all liquids
			element.high_heat_transformation = "vapor"
			element.high_heat_point = min(10000, 2.5 * properties["temperature"])
		"gas":
			element = Fluid.new()
			element.gravity_down = false
			element.density = randf_range(0.75, 1.25) * properties["density"]
			
			# Add decay to all gases
			element.decay_transformation = "empty"
			element.decay_proportion = 0.006
		"rigid_solid":
			element = Solid.new()
		"powdery_solid":
			element = Powder.new()
		"metal":
			element = Metal.new()
			element.conductivity = randf_range(0.2, 0.5)
		"creature":
			element = Critter.new()
			element.travel_proportion = randf_range(0, 1)
			element.jump_force = randf_range(0, 1)
			element.jump_proportion = randf_range(0, 1)
			
			# All creatures should be flammable
			element.high_heat_transformation = "fire"
			element.high_heat_point = min(10000, 2.5 * properties["temperature"])
		"microbe":
			element = Bacteria.new()
			element.home_material = "empty"
			element.growth_rate = randf_range(0.01, 0.04)
			element.surround_tolerance = randf_range(0, 1)
			element.loneliness_tolerance = randf_range(0, 1)
			
			# All microbes should be flammable
			element.high_heat_transformation = "fire"
			element.high_heat_point = min(10000, 2.5 * properties["temperature"])
		"laser":
			element = Laser.new()
			element.decay_proportion = randf_range(0.1, 0.5)
			element.decay_transformation = "empty"
			element.reach = randf_range(0, 1)
		"electricity":
			element = Lightning.new()
			element.fall_proportion = randf_range(0, 1)
			element.unexcited_decay_proportion = randf_range(0, 1)
		"explosive":
			element = Solid.new()
			
			# All explosives should be.. explosive
			element.high_heat_transformation = "explosion"
			element.high_heat_point = min(10000, 2.5 * properties["temperature"])
	
	element.initial_temperature = properties["temperature"]
	
	if "heat_transformation" in properties and not properties["state"] == "explosive":
		element.high_heat_transformation = properties["heat_transformation"]
		element.high_heat_point = min(10000, 2.5 * properties["temperature"])
	
	# "none" seems to be a pretty common and buggy response
	if "cold_transformation" in properties and not properties["cold_transformation"] == "none":
		element.low_heat_transformation = properties["cold_transformation"]
		element.low_heat_point = min(10000, 0.35 * properties["temperature"])
	
	element.pixel_color = GradientTexture1D.new()
	element.pixel_color.gradient = Gradient.new()
	
	# Add HDR glow to hot elements
	if properties["temperature"] > 1000:
		element.pixel_color.use_hdr = true
		element.pixel_color.gradient.set_color(0, Color(1.0, 1.0, 1.0) + Color(properties["color_0"]))
		element.pixel_color.gradient.set_color(0, Color(1.0, 1.0, 1.0) + Color(properties["color_1"]))
	else:
		element.pixel_color.gradient.set_color(0, properties["color_0"])
		element.pixel_color.gradient.set_color(1, properties["color_1"])
	
	element.ui_color = properties["color_0"]
	
	element.unique_name = element_name
	element.generated = true
	if hidden:
		element.hidden = true
	
	# Save the element to the simulation and storage
	sim.add_element(element, false, true)
	ResourceSaver.save(element, "user://" + str(randi() % 9999999999) + element_name + ".tres")
	
	return element

func create_element_from_text(element_name: String, directly_prompted: bool = true) -> bool:
	if element_name in sim.name_id_map:
		status_label.show_text("ERROR: element name already exists, perhaps as a secret element.", StatusLabel.TextType.ERROR)
		return false
	
	var prompt_name: String = clean_prompt(element_name)
	
	if len(prompt_name) == 0:
		status_label.show_text("ERROR: enter a valid element name.", StatusLabel.TextType.ERROR)
		return false
	
	# A JSON Dictionary... cannot be typed in case it is null
	var properties
	while true:
		if directly_prompted:
			request("https://122412240.xyz/sand-spoon/?reactions=1&element_name=" + prompt_name)
		else:
			request("https://122412240.xyz/sand-spoon/?element_name=" + prompt_name)
		properties = await properties_received
		if not properties:
			# Wait some time before retrying; most errors are caused by the request limit.
			await get_tree().create_timer(2.5).timeout
		else:
			break
	
	if "warning" in properties:
		status_label.show_text("ERROR: query breaks content policy.", StatusLabel.TextType.ERROR)
		return false
	
	if directly_prompted:
		var reaction_elements: Array = [properties["heat_transformation"], properties["cold_transformation"]]
		for reaction_element_name in reaction_elements:
			if reaction_element_name in sim.name_id_map:
				continue
			if not await create_element_from_text(reaction_element_name, false):
				return false
	
	realize_element(element_name, properties, not directly_prompted)
	
	return true

func prompt(element_name: String) -> void:
	status_label.show_text("STATUS: querying server, please wait...", StatusLabel.TextType.WORKING)
	if await create_element_from_text(element_name):
		element_created.emit()
		status_label.show_text("SUCCESS: element created!", StatusLabel.TextType.SUCCESS)
	_enable_button()
