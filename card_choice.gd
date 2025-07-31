extends Button

var _card_type: String

func set_card(card_type: String) -> void:
	_card_type = card_type
	
	text = _card_type

func get_card_type() -> String:
	return _card_type

func _on_pressed() -> void:
	get_node("../../").choose_player_card(_card_type)
