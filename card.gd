extends Button

var _card_type: String

func set_card_type(card_type: String) -> void:
	_card_type = card_type
	
	text = _card_type

func _on_pressed() -> void:
	if get_tree().root.get_node("Main")._game_state.get_curr_player() != 0: return
	
	# use the card
	EventBus.use_card.emit(_card_type)
	hide()
