class_name Element extends Resource
# Data: assumes byte 0 for temperature.

@export_group("UI")
## Name used in UI and code.
@export var unique_name: String

## Base color for UI components for this element
@export var ui_color: Color

@export_group("Performance")
## The proportion of process frames are skipped. Set to a value higher than 0
## to hide chunk seams and create more organic movement.
@export_range(0, 1) var skip_proportion: float = 0.3

@export_group("Heat")
@export_range(0, 10000, 0.1, "or_greater", "suffix:K") var initial_temperature: float = 293
@export_range(0, 1) var conductivity: float = 0.5
@export_subgroup("High")
@export_range(-1, 10000, 0.1, "or_greater", "suffix:K") var high_heat_point: float = -1
@export var high_heat_transformation: String = "empty"
@export_subgroup("Low")
@export_range(-1, 10000, 0.1, "or_greater", "suffix:K") var low_heat_point: float = -1
@export var low_heat_transformation: String = "empty"

var ihigh_heat_point: int 
var ilow_heat_point: int 
var iinitial_temperature: int 
var color_is_temperature_dependent: bool = false

## Called once per element while the simulation is initialized.
func initialize() -> void:
	if high_heat_point <= 0:
		ihigh_heat_point = 65535
	else:
		ihigh_heat_point = int(sqrt(high_heat_point) * 65535.0/100.0)
	if low_heat_point <= 0:
		ilow_heat_point = 0
	else:
		ilow_heat_point = int(sqrt(low_heat_point) * 65535.0/100.0)
	iinitial_temperature = int(sqrt(initial_temperature) * 65535/100.0)

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if Simulation.fast_randf() < skip_proportion:
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

func get_temperature(data: int) -> int:
	return data & 0xFFFF

func set_temperature(data: int, temperature: int) -> int:
	return (data & 0xFFFF0000) | temperature

func get_color(_sim: Simulation, _row: int, _col: int, _data: int) -> Color:
	return ui_color

func get_default_data(_sim: Simulation, _row: int, _col: int) -> int:
	return iinitial_temperature

func get_byte(data: int, index: int) -> int:
	return (data >> (index * 8)) & 0xFF

func set_byte(data: int, index: int, byte: int) -> int:
	return (data & ~(0xFF << (index * 8))) | (byte << (index * 8));
