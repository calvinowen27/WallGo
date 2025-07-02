class_name GameState

var _selected_tiles: Array[Tile] = []
var _selected_pos: Array[Vector2i] = []
var _player: int = 0
@export var _player_count: int = 2

var _grid: Array[Array]
var _grid_size: Vector2i

var _valid_tiles: Array[Tile] = []

var _mode: int = 0

func init(grid: Array[Array], grid_size: Vector2i, selected_tiles: Array[Tile], selected_pos: Array[Vector2i], player: int, player_count: int, valid_tiles: Array, mode: int) -> void:
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
