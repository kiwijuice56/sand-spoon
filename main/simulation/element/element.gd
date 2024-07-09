class_name Element extends Resource
# Data: assumes byte 0 for temperature

@export_group("UI")
## Name used in UI and code.
@export var unique_name: String

## Base color for UI components for this element
@export var ui_color: Color

@export_group("Performance")
## The proportion of process frames are skipped. Set to a value higher than 0
## to hide chunk seams and create more organic movement.
@export_range(0, 1) var skip_proportion: float = 0.3

## Called once per element while the simulation is initialized.
func initialize() -> void:
	pass

func process(_sim: Simulation, _row: int, _col: int, _data: int) -> void:
	pass

func get_color(_sim: Simulation, _row: int, _col: int, _data: int) -> Color:
	return ui_color

func get_default_data(_sim: Simulation, _row: int, _col: int) -> int:
	return 0

func get_byte(data: int, index: int) -> int:
	return (data >> (index * 8)) & 0xFF

func set_byte(data: int, index: int, byte: int) -> int:
	return (data & ~(0xFF << (index * 8))) | (byte << (index * 8));
