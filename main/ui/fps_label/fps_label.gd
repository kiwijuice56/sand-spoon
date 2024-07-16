class_name FPSLabel extends Label

func _ready() -> void:
	%RefreshTimer.timeout.connect(_on_refresh_timeout)

func _on_refresh_timeout() -> void:
	text = "fps: %02d" % Engine.get_frames_per_second()    
