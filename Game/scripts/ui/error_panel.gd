extends MarginContainer


@export var show_duration: float = 3

@export var _network: Network
@export var _error_label: Label

var _tween: Tween
var _show_timer: float = 0


func _ready() -> void:
	_network.received_packet.connect(_on_received_packet)
	_error_label.text = ""


func _process(delta: float) -> void:
	if _show_timer > 0:
		_show_timer -= delta
		if _show_timer <= 0:
			_tween = create_tween() \
				.set_ease(Tween.EASE_OUT) \
				.set_trans(Tween.TRANS_CUBIC)
			_tween.tween_property(_error_label, "self_modulate", Color(Color.WHITE, 0), 2)


func _on_received_packet(packet_id: Network.PacketID, buffer: ByteBuffer):
	if packet_id == Network.PacketID.CLIENT_REQUEST_ERROR:
		var error_text = buffer.get_utf8_string()
		_error_label.text = error_text
		_error_label.self_modulate = Color.WHITE
		if _tween and _tween.is_running():
			_tween.stop()
		_show_timer = len(error_text) * show_duration / 20.0	
