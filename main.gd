extends Node2D

class_name Main

@export var _grid_size: Vector2i
@export var _tile_scene: PackedScene
@export var _tile_size: float = 16

@onready var _center: Vector2i = _grid_size * _tile_size / 2 - Vector2(_tile_size / 2, _tile_size / 2)
@onready var _camera: Camera2D = %Camera2D

var _tile_display_grid: Array[Array] = []

var _game_state: GameState

var _wall_break: bool = false

enum {
	SIDE_TOP,
	SIDE_BOTTOM,
	SIDE_LEFT,
	SIDE_RIGHT
}

enum {
	MODE_COUNTER,
	MODE_WALL
}

var _side_dirs: Dictionary = {
	SIDE_TOP: Vector2i(0, -1),
	SIDE_BOTTOM: Vector2i(0, 1),
	SIDE_LEFT: Vector2i(-1, 0),
	SIDE_RIGHT: Vector2i(1, 0)
}

var _dir_sides: Dictionary = {
	Vector2i(0, -1): SIDE_TOP,
	Vector2i(0, 1): SIDE_BOTTOM,
	Vector2i(1, 0): SIDE_RIGHT,
	Vector2i(-1, 0): SIDE_LEFT
}

static var _valid_from_pos: Dictionary = {}

func _ready() -> void:
	for x in range(_grid_size.x):
		_tile_display_grid.append([])
		for y in range(_grid_size.y):
			var tile_display = _tile_scene.instantiate()
			tile_display.init(self, Vector2(x, y), _tile_size)
			$Tiles.add_child(tile_display)
			tile_display.position = Vector2(x, y) * tile_display.get_effective_size()
			_tile_display_grid[x].append(tile_display)
			
			var pos = Vector2i(x, y)
			var valid = []
			for dx in range(-2, 3):
				for dy in range(-2, 3):
					if Vector2(dx, dy).length() > 2: continue
					valid.append(pos + Vector2i(dx, dy))
			_valid_from_pos[pos] = valid
	
	_camera.position = _center
	
	#_bot_tree = TreeNode.new()
	#_bot_tree.init()
	
	EventBus.mode_changed.connect(_on_mode_changed)
	EventBus.counter_placed.connect(_on_counter_placed)
	EventBus.wall_placed.connect(_on_wall_placed)
	EventBus.game_over.connect(_on_game_over)
	EventBus.use_card.connect(_on_use_card)
	#EventBus.do_bot_turn.connect(_on_do_bot_turn)

	$WallButtons.size = Vector2(_tile_size, _tile_size)

	init()
	
	$EndText.position = _camera.position
	
	#place_counter_at_pos(_grid_size / 2 + Vector2i(2, 2))
	#_game_state.set_place_mode(MODE_COUNTER)

func init() -> void:
	$EndText.text = "Game Over"
	$EndText.hide()
	
	_game_state = GameState.new()
	var grid: Dictionary = {}
	
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			grid[Vector2i(x, y)] = [ false, false, false, false ]
	
	# reset card manager
	$CardManager.choose_board_card()
	$CardManager._chosen_player_cards.clear()
	$CardManager/CardChoice.show()
	for child in $CardManager/Cards.get_children():
		$CardManager/Cards.remove_child(child)
	
	#var selected_pos: Array[Vector2i] = [Vector2i(1, 3), Vector2i(5, 3)]
	_game_state.init({}, _grid_size)
	_game_state.try_place_counter_at_pos(Vector2i(1, 3))
	_game_state.next_player()
	
	_game_state._valid_pos.clear()
	_game_state.try_place_counter_at_pos(Vector2i(5, 3))
	_game_state.next_player()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _game_state.get_curr_player() == 0 and _game_state.get_place_mode() == MODE_COUNTER:
				var mouse_pos = get_global_mouse_position() + Vector2(_tile_size / 2, _tile_size / 2)
				var idx = Vector2i(clamp(mouse_pos.x / _tile_size, 0, _grid_size.x - 1), clamp(mouse_pos.y / _tile_size, 0, _grid_size.y - 1))

				_game_state.try_place_counter_at_pos(idx)
				
				_game_state.calculate_scores()
				if _game_state.get_scores()[0] != 0: EventBus.game_over.emit(_game_state)

func _process(_delta: float) -> void:
	#var scores = _game_state.get_scores()
	#if len(scores) != 0 and scores[0] != 0: return # game over
	if $EndText.visible: return
	
	#if _game_state.get_curr_player() == 0:
		#if _game_state.get_place_mode() == MODE_COUNTER and Input.is_action_just_pressed("click"):
			#var mouse_pos = get_global_mouse_position() + Vector2(_tile_size / 2, _tile_size / 2)
			#var idx = Vector2i(clamp(mouse_pos.x / _tile_size, 0, _grid_size.x - 1), clamp(mouse_pos.y / _tile_size, 0, _grid_size.y - 1))
#
			#_game_state.try_place_counter_at_pos(idx)
			#
			#_game_state.calculate_scores()
			#if _game_state.get_scores()[0] != 0: EventBus.game_over.emit(_game_state)
	#else:
	if _game_state.get_curr_player() == 1:
		_game_state.calculate_scores()
		if _game_state.get_scores()[0] != 0: EventBus.game_over.emit(_game_state)
		_on_do_bot_turn(_game_state)

func _on_wall_left_pressed() -> void:
	if _wall_break:
		_game_state.destroy_wall_on_side(SIDE_LEFT)
		var pos = _game_state.get_curr_player_selected_pos()
		_tile_display_grid[pos.x][pos.y].destroy_wall_on_side(SIDE_LEFT)
		_tile_display_grid[pos.x - 1][pos.y].destroy_wall_on_side(SIDE_RIGHT)
		
		_wall_break = false
		_game_state.set_place_mode(_game_state.get_place_mode())
	else:
		_game_state.try_place_wall_on_side(SIDE_LEFT)
	#print(_game_state.get_player_score(0))

func _on_wall_right_pressed() -> void:
	if _wall_break:
		_game_state.destroy_wall_on_side(SIDE_RIGHT)
		var pos = _game_state.get_curr_player_selected_pos()
		_tile_display_grid[pos.x][pos.y].destroy_wall_on_side(SIDE_RIGHT)
		_tile_display_grid[pos.x + 1][pos.y].destroy_wall_on_side(SIDE_LEFT)
		_wall_break = false
		_game_state.set_place_mode(_game_state.get_place_mode())
	else:
		_game_state.try_place_wall_on_side(SIDE_RIGHT)
	#print(_game_state.get_player_score(0))

func _on_wall_bottom_pressed() -> void:
	if _wall_break:
		_game_state.destroy_wall_on_side(SIDE_BOTTOM)
		var pos = _game_state.get_curr_player_selected_pos()
		_tile_display_grid[pos.x][pos.y].destroy_wall_on_side(SIDE_BOTTOM)
		_tile_display_grid[pos.x][pos.y + 1].destroy_wall_on_side(SIDE_TOP)
		_wall_break = false
		_game_state.set_place_mode(_game_state.get_place_mode())
	else:
		_game_state.try_place_wall_on_side(SIDE_BOTTOM)
	#print(_game_state.get_player_score(0))

func _on_wall_top_pressed() -> void:
	if _wall_break:
		_game_state.destroy_wall_on_side(SIDE_TOP)
		var pos = _game_state.get_curr_player_selected_pos()
		_tile_display_grid[pos.x][pos.y].destroy_wall_on_side(SIDE_TOP)
		_tile_display_grid[pos.x][pos.y - 1].destroy_wall_on_side(SIDE_BOTTOM)
		_wall_break = false
		_game_state.set_place_mode(_game_state.get_place_mode())
	else:
		_game_state.try_place_wall_on_side(SIDE_TOP)
	#print(_game_state.get_player_score(0))

func get_grid_size() -> Vector2i:
	return _grid_size

func _on_mode_changed(state: GameState, mode: int) -> void:
	if state != _game_state: return
	
	match mode:
		MODE_COUNTER:
			#_game_state.calculate_scores()
			#print("calculate")
			var scores = _game_state.get_scores()
			if len(scores) != 0 and _game_state.get_scores()[0] != 0:
				EventBus.game_over.emit(_game_state)
			if _game_state.get_curr_player() != 0: return
			
			highlight_valid_tiles()
			
			$WallButtons/WallLeft.show()
			$WallButtons/WallRight.show()
			$WallButtons/WallTop.show()
			$WallButtons/WallBottom.show()
			
			$WallButtons.hide()
		
		MODE_WALL:
			if _game_state.get_curr_player() != 0: return
			
			unhighlight_tiles()
			
			$WallButtons.show()
			
			var selected_pos = _game_state.get_curr_player_selected_pos()
			#var selected_tile = _game_state.get_curr_player_selected_tile()
			
			if selected_pos.x == 0 or _game_state.tile_at_pos_has_wall_on_side(selected_pos, _game_state.SIDE_LEFT):
				$WallButtons/WallLeft.hide()
			if selected_pos.x == _grid_size.x - 1 or _game_state.tile_at_pos_has_wall_on_side(selected_pos, _game_state.SIDE_RIGHT):
				$WallButtons/WallRight.hide()
			if selected_pos.y == 0 or _game_state.tile_at_pos_has_wall_on_side(selected_pos, _game_state.SIDE_TOP):
				$WallButtons/WallTop.hide()
			if selected_pos.y == _grid_size.y - 1 or _game_state.tile_at_pos_has_wall_on_side(selected_pos, _game_state.SIDE_BOTTOM):
				$WallButtons/WallBottom.hide()

func _on_do_bot_turn(state: GameState) -> void:
	if state != _game_state: return
	
	var t = TreeNode.new()
	t.init()

	for i in range(1000):
		var sample_state = _game_state.clone()
		t.step(sample_state)

	var best_action = t.get_best(_game_state)
	if not best_action:
		print("uh oh best action is bad")
	else:
		#print("ok good")
		
		_game_state.try_place_counter_at_pos(best_action.get_next_pos())
		
		if not _game_state.try_place_wall_on_side(best_action.get_wall_side()):
			print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!place wall failed")

func highlight_valid_tiles(jump: bool = false, extra_space: bool = false) -> void:
	_game_state._valid_pos = _game_state.find_valid_pos(_game_state.get_curr_player(), jump, extra_space)
	for pos in _game_state.get_valid_pos():
		_tile_display_grid[pos.x][pos.y].highlight()
		#tile.get_display().highlight()

func unhighlight_tiles() -> void:
	for pos in _game_state.get_valid_pos():
		_tile_display_grid[pos.x][pos.y].unhighlight()
		#tile.get_display().unhighlight()

func _on_counter_placed(state: GameState, pos: Vector2) -> void:
	if state != _game_state: return
	
	var prev_pos = _game_state.get_curr_player_prev_selected_pos()
	_tile_display_grid[prev_pos.x][prev_pos.y].remove_counter()
	_tile_display_grid[pos.x][pos.y].place_counter(_game_state.get_curr_player())
	$WallButtons.position = _tile_display_grid[pos.x][pos.y].position - Vector2(_tile_size, _tile_size) / 2

func _on_wall_placed(state: GameState, pos: Vector2i, side: int) -> void:
	if state != _game_state: return
	
	_tile_display_grid[pos.x][pos.y].place_wall_on_side(side)

func _on_game_over(state: GameState) -> void:
	if state != _game_state: return
	
	$EndText.show()
	var winner = 0
	var max_score = 0
	
	var scores = _game_state.get_scores()
	for i in range(len(scores)):
		if scores[i] > max_score:
			max_score = scores[i]
			winner = i
		
	$EndText.text += "\nPlayer %d wins" % winner

func reset() -> void:
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			var tile = _tile_display_grid[x][y]
			tile.unhighlight()
			tile.remove_counter()
			tile.reset_walls()
	
	init()

func _on_reset_button_pressed() -> void:
	reset()

func _on_use_card(card: String) -> void:
	match card:
		"wall break":
			$WallButtons.show()
			
			var player_pos = _game_state.get_selected_pos(0)
			$WallButtons.position = _tile_display_grid[player_pos.x][player_pos.y].position - Vector2(_tile_size, _tile_size) / 2
			
			if not _game_state.tile_at_pos_has_wall_on_side(player_pos, SIDE_LEFT):
				$WallButtons/WallLeft.hide()
			if not _game_state.tile_at_pos_has_wall_on_side(player_pos, SIDE_RIGHT):
				$WallButtons/WallRight.hide()
			if not _game_state.tile_at_pos_has_wall_on_side(player_pos, SIDE_TOP):
				$WallButtons/WallTop.hide()
			if not _game_state.tile_at_pos_has_wall_on_side(player_pos, SIDE_BOTTOM):
				$WallButtons/WallBottom.hide()
			
			_wall_break = true
			
		"+1 space":
			unhighlight_tiles()
			
			highlight_valid_tiles(false, true)
		"wall jump":
			unhighlight_tiles()
			
			highlight_valid_tiles(true)
		"switch places":
			unhighlight_tiles()
			
			var pos0 = _game_state.get_selected_pos(0)
			var pos1 = _game_state.get_selected_pos(1)
			
			var temp = _game_state._selected_pos[0]
			_game_state._selected_pos[0] = _game_state._selected_pos[1]
			_game_state._selected_pos[1] = temp
			
			_tile_display_grid[pos0.x][pos0.y].place_counter(1)
			_tile_display_grid[pos1.x][pos1.y].place_counter(0)
			
			highlight_valid_tiles()
