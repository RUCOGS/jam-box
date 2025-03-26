class_name UIScaler
extends Node


signal resolution_platform_changed(is_mobile: bool)


static var global: UIScaler

@export var is_mobile: bool
var original_content_scale_size: Vector2i
var original_aspect_ratio: float


func _enter_tree() -> void:
	if global != null:
		queue_free()
		return
	global = self


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if global == self:
			global = null


func _ready():
	original_content_scale_size = get_tree().root.content_scale_size
	original_aspect_ratio = float(original_content_scale_size.y) / original_content_scale_size.x
	get_window().size_changed.connect(_on_window_size_changed)
	_on_window_size_changed()


func _on_window_size_changed():
	var size = get_window().size
	var aspect_ratio: float = float(size.y) / size.x
	is_mobile = aspect_ratio > original_aspect_ratio * 2
	resolution_platform_changed.emit(is_mobile)
	if is_mobile:
		get_tree().root.content_scale_size = Vector2i(390, 866) / 1.25
	else:
		get_tree().root.content_scale_size = original_content_scale_size
