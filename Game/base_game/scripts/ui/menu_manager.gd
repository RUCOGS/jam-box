extends Control
class_name MenuManager


func go_to_menu(menu_name: String):
	for child: Control in get_children():
		child.visible = child.name == menu_name
