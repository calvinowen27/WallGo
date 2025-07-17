extends Node2D

@export var _grid_size: Vector2i
@export var _tile_scene: PackedScene
@export var _tile_size: float = 16

@onready var _center: Vector2i = _grid_size * _tile_size / 2 - Vector2(_tile_size / 2, _tile_size / 2)
@onready var _camera: Camera2D = %Camera2D

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

	$WallButtons.size = Vector2(_tile_size, _tile_size)

	_game_state = GameState.new()
	var grid = _game_state.get_grid()
	for x in range(_grid_size.x):
		grid.append([])
		for y in range(_grid_size.y):
			var tile = _tile_scene.instantiate()
			tile.init(self, Vector2(x, y), _tile_size)
			$Tiles.add_child(tile)
			tile.position = Vector2(x, y) * tile.get_effective_size()
			grid[x].append(tile)
	
	for i in range(_game_state.get_player_count()):
		_game_state.select_tile(-1, Vector2i.ZERO)
	
	for i in range(_game_state.get_player_count()):
		place_counter_at_pos(_grid_size / 2 + Vector2i(i, i))
		_set_place_mode(MODE_COUNTER)
	
	$EndText.position = _camera.position
	
	#place_counter_at_pos(_grid_size / 2 + Vector2i(2, 2))
	#_set_place_mode(MODE_COUNTER)

func _process(_delta: float) -> void:
	if _game_state.get_player() == 0:
		if Input.is_action_just_pressed("click"):
			var mouse_pos = get_global_mouse_position() + Vector2(_tile_size / 2, _tile_size / 2)
			var idx = Vector2i(clamp(mouse_pos.x / _tile_size, 0, _grid_size.x - 1), clamp(mouse_pos.y / _tile_size, 0, _grid_size.y - 1))

			if _game_state.get_mode() == MODE_COUNTER:
				if try_place_counter_at_pos(idx):
					_set_place_mode(MODE_WALL)
	else:
		var valid_tiles = _game_state.get_valid_tiles()
		var r = randi_range(0, len(valid_tiles) - 1)
		var tile_pos = valid_tiles[r].get_grid_pos()
		if try_place_counter_at_pos(tile_pos):
			_set_place_mode(MODE_WALL)
		
		r = randi_range(0, 3)
		try_place_wall_on_side(r)

func try_place_wall_on_side(side: int) -> bool:
	var next_pos = _game_state.get_player_selected_pos() + _side_dirs[side]
	if next_pos.x < 0 or next_pos.y < 0 or next_pos.x > _grid_size.x - 1 or next_pos.y > _grid_size.y - 1: return false
	
	if not _game_state.get_player_selected_tile().place_wall_on_side(side): return false

	_game_state.get_tile(next_pos).place_wall_on_side(_get_opposite_side(side))

	calculate_scores()
	
	_set_place_mode(MODE_COUNTER)

	return true

func try_place_counter_at_pos(pos: Vector2i) -> bool:
	if not _game_state.tile_at_pos_valid(pos): return false
	
	place_counter_at_pos(pos)
	
	return true

func place_counter_at_pos(pos: Vector2i) -> void:
	if _game_state.get_player_selected_tile(): _game_state.get_player_selected_tile().remove_counter()

	var tile = _game_state.get_tile(pos) as Tile
	tile.place_counter(_game_state.get_player())
	_game_state.select_player_tile(tile.get_grid_pos())

	$WallButtons.position = _game_state.get_player_selected_tile().position - Vector2(_tile_size, _tile_size) / 2

func calculate_scores() -> void:
	var shapes = []
	
	for player in range(_game_state.get_player_count()):
		var tile = _game_state.get_player_selected_tile()
		var tile_in_shape = false
		for shape in shapes:
			if tile in shape: tile_in_shape = true
		
		if tile_in_shape:
			continue
		
		var shape = [ tile ]
		var checked = []
	
		for from_tile in shape:
			if from_tile in checked: continue
			checked.append(from_tile)
			for dir in _dir_sides.keys():
				var to_pos = from_tile.get_grid_pos() + dir
				if not is_pos_in_grid(to_pos): continue
				if _game_state.get_tile(to_pos) in shape: continue
				if _can_move_to_from(to_pos, from_tile.get_grid_pos()):
					shape.append(_game_state.get_tile(to_pos))
	
		shapes.append(shape)
	
	for shape in shapes:
		print(shape.size())
	
	if shapes.size() == _game_state.get_player_count(): $EndText.show()

func is_pos_in_grid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < _grid_size.x and pos.y < _grid_size.y

func _on_wall_left_pressed() -> void:
	try_place_wall_on_side(SIDE_LEFT)

func _on_wall_right_pressed() -> void:
	try_place_wall_on_side(SIDE_RIGHT)

func _on_wall_bottom_pressed() -> void:
	try_place_wall_on_side(SIDE_BOTTOM)

func _on_wall_top_pressed() -> void:
	try_place_wall_on_side(SIDE_TOP)

func _get_opposite_side(side: int) -> int:
	match side:
		SIDE_TOP: return SIDE_BOTTOM
		SIDE_BOTTOM: return SIDE_TOP
		SIDE_LEFT: return SIDE_RIGHT
		SIDE_RIGHT: return SIDE_LEFT
	
	return -1

func _set_place_mode(mode: int) -> void:
	_game_state.set_mode(mode)
	match mode:
		MODE_COUNTER:
			_game_state.next_player()
			
			$WallButtons/WallLeft.show()
			$WallButtons/WallRight.show()
			$WallButtons/WallTop.show()
			$WallButtons/WallBottom.show()
			
			$WallButtons.hide()
			highlight_valid_tiles()
			
		MODE_WALL:
			$WallButtons.show()
			unhighlight_tiles()
			
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

func _can_move_to_from(to_pos: Vector2i, from_pos: Vector2i) -> bool:
	var dir = to_pos - from_pos
	if dir.length() > 1: return false
	if to_pos.x > _grid_size.x - 1 or to_pos.y > _grid_size.y - 1: return false
	if to_pos.x < 0 or to_pos.y < 0: return false
	if from_pos.x > _grid_size.x - 1 or from_pos.y > _grid_size.y - 1: return false
	if from_pos.x < 0 or from_pos.y < 0: return false
	
	var to = _game_state.get_tile(to_pos)
	
	#if to in _selected_tiles and not to == _selected_tiles[_player]: return false
	
	var from = _game_state.get_tile(from_pos)
	
	var side = _dir_sides[dir]
	
	return not from.has_wall_on_side(side) and not to.has_wall_on_side(_get_opposite_side(side))

func highlight_valid_tiles() -> void:
	if not _game_state.get_player_selected_tile(): return
	_game_state.clear_valid_tiles()
	_game_state.add_valid_tile(_game_state.get_player_selected_tile())
	
	var new_valid_tiles: Array[Tile] = []
	var checked = []
	
	for i in range(2):
		for from_tile in _game_state.get_valid_tiles():
			if from_tile in checked: continue
			checked.append(from_tile)
			for dir in _dir_sides.keys():
				var to_pos = from_tile.get_grid_pos() + dir
				if _can_move_to_from(to_pos, from_tile.get_grid_pos()):
					var to = _game_state.get_tile(to_pos)
					
					if not _game_state.tile_selected(to) or to == _game_state.get_player_selected_tile():
						new_valid_tiles.append(to)
		_game_state.set_valid_tiles(new_valid_tiles)
	
	for tile in _game_state.get_valid_tiles():
		tile.highlight()

func unhighlight_tiles() -> void:
	for tile in _game_state.get_valid_tiles():
		tile.unhighlight()

func get_grid_size() -> Vector2i:
	return _grid_size
