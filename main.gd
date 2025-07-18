extends Node2D

@export var _grid_size: Vector2i
@export var _tile_scene: PackedScene
@export var _tile_size: float = 16

@onready var _center: Vector2i = _grid_size * _tile_size / 2 - Vector2(_tile_size / 2, _tile_size / 2)
@onready var _camera: Camera2D = %Camera2D

var _tile_display_grid: Array[Array] = []
var _selected_tiles = []

#var _selected_tiles: Array[Tile] = []
#var _selected_pos: Array[Vector2i] = []
#var _player: int = 0
#@export var _player_count: int = 2
#
#var _grid: Array[Array]
#
#var _valid_tiles: Array
#
#var _mode: int = 0

var _game_state: GameState

enum {
	SIDE_TOP,
	SIDE_BOTTOM,
	SIDE_RIGHT,
	SIDE_LEFT
}

enum {
	MODE_COUNTER,
	MODE_WALL
}

var _side_dirs: Dictionary = {
	SIDE_TOP: Vector2i(0, -1),
	SIDE_BOTTOM: Vector2i(0, 1),
	SIDE_RIGHT: Vector2i(1, 0),
	SIDE_LEFT: Vector2i(-1, 0)
}

var _dir_sides: Dictionary = {
	Vector2i(0, -1): SIDE_TOP,
	Vector2i(0, 1): SIDE_BOTTOM,
	Vector2i(1, 0): SIDE_RIGHT,
	Vector2i(-1, 0): SIDE_LEFT
}

var _adjacent_sides: Dictionary = {
	SIDE_TOP: [ SIDE_TOP, SIDE_LEFT, SIDE_RIGHT ],
	SIDE_BOTTOM: [ SIDE_BOTTOM, SIDE_LEFT, SIDE_RIGHT ],
	SIDE_LEFT: [ SIDE_LEFT, SIDE_TOP, SIDE_BOTTOM ],
	SIDE_RIGHT: [ SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM ],
}

func _ready() -> void:
	_camera.position = _center
	
	EventBus.mode_changed.connect(_on_mode_changed)
	EventBus.counter_placed.connect(_on_counter_placed)
	EventBus.game_over.connect(_on_game_over)

	$WallButtons.size = Vector2(_tile_size, _tile_size)

	_game_state = GameState.new()
	var grid = _game_state.get_grid()
	_game_state.set_grid_size(_grid_size)
	_game_state.set_tile_size(_tile_size)
	for x in range(_grid_size.x):
		_tile_display_grid.append([])
		grid.append([])
		for y in range(_grid_size.y):
			var tile_display = _tile_scene.instantiate()
			tile_display.init(self, Vector2(x, y), _tile_size)
			$Tiles.add_child(tile_display)
			tile_display.position = Vector2(x, y) * tile_display.get_effective_size()
			_tile_display_grid[x].append(tile_display)
			
			grid[x].append(tile_display.get_tile())
	
	for i in range(_game_state.get_player_count()):
		_game_state.select_tile(-1, Vector2i.ZERO)
	
	for i in range(_game_state.get_player_count()):
		var pos = _grid_size / 2 + Vector2i(i, i)
		_game_state.place_counter_at_pos(pos)
		_game_state.set_place_mode(MODE_COUNTER)
	
	$EndText.position = _camera.position
	
	#place_counter_at_pos(_grid_size / 2 + Vector2i(2, 2))
	#_game_state.set_place_mode(MODE_COUNTER)

func _process(_delta: float) -> void:
	if _game_state.get_player() == 0:
		if _game_state.get_mode() == MODE_COUNTER and Input.is_action_just_pressed("click"):
			var mouse_pos = get_global_mouse_position() + Vector2(_tile_size / 2, _tile_size / 2)
			var idx = Vector2i(clamp(mouse_pos.x / _tile_size, 0, _grid_size.x - 1), clamp(mouse_pos.y / _tile_size, 0, _grid_size.y - 1))

			_game_state.try_place_counter_at_pos(idx)
			
			_game_state.calculate_scores()
			if len(_game_state.get_scores()) != 0: EventBus.game_over.emit()
	else:
		#var valid_tiles = _game_state.get_valid_tiles()
		#var r = randi_range(0, len(valid_tiles) - 1)
		#var tile_pos = valid_tiles[r].get_grid_pos()
		#_game_state.try_place_counter_at_pos(tile_pos)
		#
		#r = randi_range(0, 3)
		#_game_state.try_place_wall_on_side(r)
		
		var t = TreeNode.new()
		t.init()
		
		for i in range(250):
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
		
		#print(_game_state.get_player_score(1))

func _on_wall_left_pressed() -> void:
	_game_state.try_place_wall_on_side(SIDE_LEFT)
	#print(_game_state.get_player_score(0))

func _on_wall_right_pressed() -> void:
	_game_state.try_place_wall_on_side(SIDE_RIGHT)
	#print(_game_state.get_player_score(0))

func _on_wall_bottom_pressed() -> void:
	_game_state.try_place_wall_on_side(SIDE_BOTTOM)
	#print(_game_state.get_player_score(0))

func _on_wall_top_pressed() -> void:
	_game_state.try_place_wall_on_side(SIDE_TOP)
	#print(_game_state.get_player_score(0))

func get_grid_size() -> Vector2i:
	return _grid_size

func _on_mode_changed(mode: int) -> void:
	match mode:
		MODE_COUNTER:
			if len(_game_state.get_scores()) != 0:
				EventBus.game_over.emit()
			
			if _game_state.get_player() != 0: return
			
			highlight_valid_tiles()
			
			$WallButtons/WallLeft.show()
			$WallButtons/WallRight.show()
			$WallButtons/WallTop.show()
			$WallButtons/WallBottom.show()
			
			$WallButtons.hide()
		
		MODE_WALL:
			if _game_state.get_player() != 0: return
			
			unhighlight_tiles()
			
			$WallButtons.show()
			
			var selected_pos = _game_state.get_player_selected_pos()
			var selected_tile = _game_state.get_player_selected_tile()
			
			if selected_pos.x == 0 or _game_state.get_player_selected_tile().has_wall_on_side(SIDE_LEFT):
				$WallButtons/WallLeft.hide()
			if selected_pos.x == _grid_size.x - 1 or selected_tile.has_wall_on_side(SIDE_RIGHT):
				$WallButtons/WallRight.hide()
			if selected_pos.y == 0 or selected_tile.has_wall_on_side(SIDE_TOP):
				$WallButtons/WallTop.hide()
			if selected_pos.y == _grid_size.y - 1 or selected_tile.has_wall_on_side(SIDE_BOTTOM):
				$WallButtons/WallBottom.hide()

func highlight_valid_tiles() -> void:
	for tile in _game_state.get_valid_tiles():
		tile.get_display().highlight()

func unhighlight_tiles() -> void:
	for tile in _game_state.get_valid_tiles():
		tile.get_display().unhighlight()

func _on_counter_placed(pos: Vector2) -> void:
	$WallButtons.position = _tile_display_grid[pos.x][pos.y].position - Vector2(_tile_size, _tile_size) / 2

func _on_game_over() -> void:
	$EndText.show()
	var winner = 0
	var max_score = 0
	
	var scores = _game_state.get_scores()
	for i in range(len(scores)):
		if scores[i] > max_score:
			max_score = scores[i]
			winner = i
			
	$EndText.text += "\nPlayer %d wins" % winner
