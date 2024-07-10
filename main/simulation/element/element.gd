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
@export_range(0, 255) var initial_temperature: int = 128
@export var conductivity: float = 0.5

var color_is_temperature_dependent: bool = false

## Called once per element while the simulation is initialized.
func initialize() -> void:
	pass

func process(sim: Simulation, row: int, col: int, data: int) -> bool:
	if Simulation.fast_randf() < skip_proportion:
		return false
	if Simulation.fast_randf() < conductivity:
		var new_temp: int = (get_byte(data, 0) + sim.get_chunk_temp(row, col)) / 2
		sim.set_data(row, col, set_byte(data, 0, new_temp), color_is_temperature_dependent)
	return true

func get_color(_sim: Simulation, _row: int, _col: int, _data: int) -> Color:
	return ui_color

func get_default_data(_sim: Simulation, _row: int, _col: int) -> int:
	return initial_temperature

func get_byte(data: int, index: int) -> int:
	return (data >> (index * 8)) & 0xFF

func set_byte(data: int, index: int, byte: int) -> int:
	return (data & ~(0xFF << (index * 8))) | (byte << (index * 8));
