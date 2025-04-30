extends Button


func _ready() -> void:
	LimboConsole.register_command(LimboConsole.close_console, "hide", "hide the console")
	pressed.connect(_on_pressed)


func _on_pressed():
	LimboConsole.open_console()
