class_name Element extends Resource

@export var unique_name: String
@export var color: Color
@export var skip_proportion: float = 0.3

## Called once per element while the simulation is initialized.
func initialize() -> void:
	pass

func process(_sim: Simulation, _row: int, _col: int, _data: int) -> void:
	pass

func get_color(_sim: Simulation, _row: int, _col: int, _data: int) -> Color:
	return color

func get_default_data(_sim: Simulation, _row: int, _col: int) -> int:
	return 0
