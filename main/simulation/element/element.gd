@tool
@icon("res://main/icons/element_icon.svg")
class_name Element extends Resource
# Data: assumes byte 0 and 1 for temperature.

@export_group("Appearance")
## Name used in the UI and by other element scripts.
@export var unique_name: String
## If true, this element will not appear in the UI.
@export var hidden: bool = false
## Base color for UI components involving this element, such as buttons.
@export var ui_color: Color

@export_group("Heat")
@export_range(0, 10000, 0.1, "suffix:K") var initial_temperature: float = 293
## The proportion of frames that this particle updates its temperature.
## More conductive elements will react faster to local changes in temperature.
@export_range(0, 1) var conductivity: float = 0.5
@export_subgroup("High")
## The temperature at which this element will transform into high_heat_transformation. 
## No effect if set to -1.
@export_range(-1, 10000, 0.1, "suffix:K") var high_heat_point: float = -1
@export var high_heat_transformation: String = "empty"
@export_subgroup("Low")
## The temperature at which this element will transform into low_heat_transformation. 
## No effect if set to -1.
@export_range(-1, 10000, 0.1, "suffix:K") var low_heat_point: float = -1
@export var low_heat_transformation: String = "empty"

@export_group("Explosion")
## The resistance this element has to destruction when interacted with by elements such as lasers
## and bombs.
@export_range(0, 1) var explosion_resistance: float = 0.1

@export_group("Decay")
## The probability that this element will decay into decay_transformation when processed.
@export_range(0, 1) var decay_proportion: float = 0.0
@export var decay_transformation: String = "empty"

@export_group("Transformation")
## The proportion of frames that this particle checks its surroundings to undergo reactions.
## For performance reasons, values < 0.05 are recommended.
@export_range(0, 1) var reactivity: float = 0.0
var reactants: Array[String] = []
var products: Array[String] = []

var ihigh_heat_point: int 
var ilow_heat_point: int 
var iinitial_temperature: int 

# Set by inheriting classes if they change color with temperature, such as metals.
var color_is_temperature_dependent: bool = false

# https://www.reddit.com/r/godot/comments/11cpc9z/property_array_in_gdscript/
func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary] = []

	properties.append({
		"name": "reaction_count",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_ARRAY | PROPERTY_USAGE_DEFAULT,
		"class_name": "Reactions,reaction_",
		"hint": PROPERTY_HINT_NONE
	})
	
	for i in reactants.size():
		properties.append({
			"name": "reaction_%d/reactant" % i,
			"type": TYPE_STRING
		})
		properties.append({
			"name": "reaction_%d/product" % i,
			"type": TYPE_STRING
		})
	
	return properties

# https://www.reddit.com/r/godot/comments/11cpc9z/property_array_in_gdscript/
func _get(property: Variant) -> Variant:
	if property == "reaction_count":
		return reactants.size()
	if property.begins_with("reaction_"):
		var parts: PackedStringArray = property.trim_prefix("reaction_").split("/")
		var i: int = parts[0].to_int()
		if parts[1] == "reactant":
			return reactants[i]
		else:
			return products[i]
	return null

# https://www.reddit.com/r/godot/comments/11cpc9z/property_array_in_gdscript/
func _set(property: StringName, value: Variant) -> bool:
	if property == "reaction_count":
		reactants.resize(value)
		products.resize(value)
		for i in reactants.size():
			if not products[i] is String:
				products[i] = ""
			if not products[i] is String:
				reactants[i] = ""
		notify_property_list_changed()
	elif property.begins_with("reaction_"):
		var parts: PackedStringArray = property.trim_prefix("reaction_").split("/")
		var i: int = parts[0].to_int()
		if parts[1] == "reactant":
			reactants[i] = value
		else:
			products[i] = value
	return true

## Called once per element while the simulation is initialized. Must be called
## to properly set up class attributes.
func initialize() -> void:
	if high_heat_point <= 0:
		ihigh_heat_point = 65535
	else:
		ihigh_heat_point = convert_temperature(high_heat_point)
	if low_heat_point <= 0:
		ilow_heat_point = 0
	else:
		ilow_heat_point = convert_temperature(low_heat_point)
	iinitial_temperature = convert_temperature(initial_temperature)

## Called by the simulation when it encounters this element at row, col.
func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if Simulation.fast_randf() < decay_proportion:
		sim.set_element(row, col, decay_transformation)
		return false
	if len(reactants) > 0 and Simulation.fast_randf() < reactivity:
		for i in len(reactants):
			if sim.is_touching(row, col, reactants[i]):
				sim.set_element(row, col, products[i])
				return false
	if Simulation.fast_randf() < conductivity:
		var new_temp: int = (get_temperature(data) + sim.get_chunk_temp(row, col)) >> 1
		if new_temp > ihigh_heat_point:
			sim.set_element(row, col, high_heat_transformation)
			return false
		if new_temp < ilow_heat_point:
			sim.set_element(row, col, low_heat_transformation)
			return false
		sim.set_data(row, col, set_temperature(data, new_temp), color_is_temperature_dependent)
	return true

## Returns the color of the particle of this element type at row, col.
func get_color(_sim: Simulation, _row: int, _col: int, _data: int) -> Color:
	return ui_color

## Return the default data integer when a new particle of this element type is created.
func get_default_data(_sim: Simulation, _row: int, _col: int) -> int:
	return iinitial_temperature

## Called by the randomizer. Returns a duplicate of this element with randomized attributes.
func create_random() -> Element:
	var copy: Element = self.duplicate()
	return copy

static func get_temperature(data: int) -> int:
	return data & 0xFFFF

static func set_temperature(data: int, temperature: int) -> int:
	return (data & 0xFFFF0000) | temperature

# Converts kelvin temperature (as a flaot) into an internal format (as a 16-bit int). 
static func convert_temperature(kelvin_temp: float) -> int:
	return int(sqrt(kelvin_temp) * 65535.0/100.0)

static func get_byte(data: int, index: int) -> int:
	return (data >> (index << 3)) & 0xFF

static func set_byte(data: int, index: int, byte: int) -> int:
	return (data & ~(0xFF << (index << 3))) | (byte << (index << 3));
