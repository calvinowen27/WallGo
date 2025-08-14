extends Control

class_name CardManager

@export var _card_choice_scene: PackedScene
@export var _card_scene: PackedScene

var _board_cards = [ "flood", "acid rain", "lava step", "nothing" ]
var _player_cards = [ "+1 space", "wall break", "switch places", "wall jump" ]

var _chosen_board_card: String
var _chosen_player_cards: Array[String]

func _ready() -> void:
	for card_type in _player_cards:
		var card = _card_choice_scene.instantiate()
		card.set_card(card_type)
		$CardChoice.add_child(card)

func choose_board_card() -> String:
	#return "lava step"
	return "nothing"
	#return _board_cards.pick_random()

func choose_player_card(card: String) -> void:
	if len(_chosen_player_cards) == 2: return
	
	_chosen_player_cards.append(card)
	
	var new_card = _card_scene.instantiate()
	new_card.set_card_type(card)
	
	$Cards.add_child(new_card)
	
	if len(_chosen_player_cards) == 2:
		$CardChoice.hide()
		$ChoiceLabel.hide()

func use_card(card: String) -> void:
	print("use ", card, " card")
