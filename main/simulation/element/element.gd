class_name Element extends Resource

@export var unique_name: String
@export var color: Color

func process(_sim: Simulation, _row: int, _col: int) -> void:
	pass

func get_color(_sim: Simulation, _row: int, _col: int) -> Color:
	return color
