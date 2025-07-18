class_name GameState

var _tile_size: float = 16

var _selected_tiles: Array[Tile] = []
var _selected_pos: Array[Vector2i] = []
var _player: int = 0
@export var _player_count: int = 2

var _grid: Array[Array]
var _grid_size: Vector2i

var _valid_tiles: Array[Tile] = []

var _mode: int = 0

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

func init(grid: Array[Array], grid_size: Vector2i, selected_tiles: Array[Tile], selected_pos: Array[Vector2i], player: int, player_count: int, valid_tiles: Array, mode: int, tile_size: int = 16) -> void:
	_grid = grid.duplicate(true)
	_grid_size = grid_size
	
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			var pos = Vector2i(x, y)
			var tile = _grid[x][y]
			for i in range(len(selected_tiles)):
				if pos == selected_tiles[i].get_grid_pos():
					_selected_tiles.insert(i, tile)
	
	_selected_pos = selected_pos.duplicate(true)
	
	_player = player
	_player_count = player_count
	
	for tile in valid_tiles:
		_valid_tiles.append(_grid[tile.x][tile.y])
	
	_mode = mode
	
	_tile_size = tile_size

func get_grid() -> Array[Array]:
	return _grid

func select_tile(player: int, pos: Vector2i) -> void:
	if player == -1:
		_selected_tiles.append(null)
		_selected_pos.append(Vector2i.ZERO)
		return
	
	_selected_tiles[player] = _grid[pos.x][pos.y]
	_selected_pos[player] = pos

func select_player_tile(pos: Vector2i) -> void:
	select_tile(_player, pos)

func get_selected_pos(player: int) -> Vector2i:
	return _selected_pos[player]

func get_player_selected_pos() -> Vector2i:
	return get_selected_pos(_player)

func get_selected_tile(player: int) -> Tile:
	return _selected_tiles[player]

func get_player_selected_tile() -> Tile:
	return get_selected_tile(_player)

func tile_selected(tile: Tile) -> bool:
	return tile in _selected_tiles

func get_tile(pos: Vector2i) -> Tile:
	return _grid[pos.x][pos.y]

func tile_at_pos_valid(pos: Vector2i) -> bool:
	return _grid[pos.x][pos.y] in _valid_tiles

func get_player_count() -> int:
	return _player_count

func get_mode() -> int:
	return _mode

func set_mode(mode: int) -> void:
	_mode = mode

func get_player() -> int:
	return _player

func next_player() -> int:
	_player = (_player + 1) % _player_count
	return _player

func clear_valid_tiles() -> void:
	_valid_tiles.clear()

func add_valid_tile(tile: Tile) -> void:
	_valid_tiles.append(tile)

func get_valid_tiles() -> Array[Tile]:
	return _valid_tiles

func set_valid_tiles(new_valid_tiles: Array[Tile]) -> void:
	_valid_tiles = new_valid_tiles.duplicate()

func duplicate() -> GameState:
	var new_state = GameState.new()
	
	var new_grid = _grid.duplicate(true)
	var selected_pos = _selected_pos.duplicate()
	var selected_tiles: Array[Tile] = []
	
	for pos in selected_pos:
		selected_tiles.append(new_grid[pos.x][pos.y])
	
	new_state.init(new_grid, _grid_size, selected_tiles, selected_pos, _player, _player_count, _valid_tiles.duplicate(true), _mode, _tile_size)
	
	return new_state

func try_place_wall_on_side(side: int) -> bool:
	var next_pos = get_player_selected_pos() + _side_dirs[side]
	if next_pos.x < 0 or next_pos.y < 0 or next_pos.x > _grid_size.x - 1 or next_pos.y > _grid_size.y - 1: return false
	
	if not get_player_selected_tile().place_wall_on_side(side): return false

	get_tile(next_pos).place_wall_on_side(_get_opposite_side(side))

	calculate_scores()
	
	set_place_mode(MODE_COUNTER)

	return true

func try_place_counter_at_pos(pos: Vector2i) -> bool:
	if not tile_at_pos_valid(pos): return false
	
	place_counter_at_pos(pos)
	
	set_place_mode(MODE_WALL)
	
	return true

func place_counter_at_pos(pos: Vector2i) -> void:
	if get_player_selected_tile(): get_player_selected_tile().remove_counter()

	var tile = get_tile(pos) as Tile
	tile.place_counter(get_player())
	select_player_tile(tile.get_grid_pos())

	EventBus.counter_placed.emit(tile.position)

func calculate_scores() -> void:
	var shapes = []
	
	for player in range(get_player_count()):
		var tile = get_selected_tile(player)
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
				if get_tile(to_pos) in shape: continue
				if _can_move_to_from(to_pos, from_tile.get_grid_pos()):
					shape.append(get_tile(to_pos))
	
		shapes.append(shape)
	
	print(len(shapes), " shapes:")
	for shape in shapes:
		print("\t", len(shape))
	print()
	
	if len(shapes) == get_player_count(): EventBus.game_over.emit()

func is_pos_in_grid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < _grid_size.x and pos.y < _grid_size.y

func _get_opposite_side(side: int) -> int:
	match side:
		SIDE_TOP: return SIDE_BOTTOM
		SIDE_BOTTOM: return SIDE_TOP
		SIDE_LEFT: return SIDE_RIGHT
		SIDE_RIGHT: return SIDE_LEFT
	
	return -1

func set_place_mode(mode: int) -> void:
	set_mode(mode)
	match mode:
		MODE_COUNTER:
			next_player()
			
			EventBus.mode_changed.emit(MODE_COUNTER)
			highlight_valid_tiles()
			
		MODE_WALL:
			EventBus.mode_changed.emit(MODE_WALL)
			
			unhighlight_tiles()

func _can_move_to_from(to_pos: Vector2i, from_pos: Vector2i) -> bool:
	var dir = to_pos - from_pos
	if dir.length() > 1: return false
	if to_pos.x > _grid_size.x - 1 or to_pos.y > _grid_size.y - 1: return false
	if to_pos.x < 0 or to_pos.y < 0: return false
	if from_pos.x > _grid_size.x - 1 or from_pos.y > _grid_size.y - 1: return false
	if from_pos.x < 0 or from_pos.y < 0: return false
	
	var to = get_tile(to_pos)
	
	#if to in _selected_tiles and not to == _selected_tiles[_player]: return false
	
	var from = get_tile(from_pos)
	
	var side = _dir_sides[dir]
	
	return not from.has_wall_on_side(side) and not to.has_wall_on_side(_get_opposite_side(side))

func highlight_valid_tiles() -> void:
	if not get_player_selected_tile(): return
	clear_valid_tiles()
	add_valid_tile(get_player_selected_tile())
	
	var new_valid_tiles: Array[Tile] = []
	var checked = []
	
	for i in range(2):
		for from_tile in get_valid_tiles():
			if from_tile in checked: continue
			checked.append(from_tile)
			for dir in _dir_sides.keys():
				var to_pos = from_tile.get_grid_pos() + dir
				if _can_move_to_from(to_pos, from_tile.get_grid_pos()):
					var to = get_tile(to_pos)
					
					if not tile_selected(to) or to == get_player_selected_tile():
						new_valid_tiles.append(to)
		set_valid_tiles(new_valid_tiles)
	
	for tile in get_valid_tiles():
		tile.highlight()

func unhighlight_tiles() -> void:
	for tile in get_valid_tiles():
		tile.unhighlight()

func set_grid_size(grid_size: Vector2i) -> void:
	_grid_size = grid_size

func set_tile_size(tile_size: float) -> void:
	_tile_size = tile_size
