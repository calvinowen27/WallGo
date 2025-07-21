extends Node

class_name GameState

var _tile_size: float = 16

var _selected_tiles: Array[Tile] = []
var _selected_pos: Array[Vector2i] = []
var _player: int = 0
@export var _player_count: int = 2

var _grid: Array[Array]
var _empty_grid: Array[Array]
var _all_tiles: Array[Tile]
var _grid_size: Vector2i

var _valid_tiles: Array[Tile] = []

var _mode: int = 0

var _score: Array[int]

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

func init(grid: Array[Array], grid_size: Vector2i, selected_pos: Array[Vector2i], player: int, player_count: int, valid_tiles: Array, mode: int, tile_size: int = 16) -> void:
	#_grid = grid.duplicate(true)
	
	#for x in grid_size.x:
		#_grid.append([])
		#for y in grid_size.y:
			#var tile = Tile.new()
			#tile.init(self, Vector2(x, y))
			#_grid[x].append(tile)
	
	_grid = grid
	
	_grid_size = grid_size
	
	for x in range(_grid_size.x):
		_empty_grid.append([])
		for y in range(_grid_size.y):
			_empty_grid[x].append(null)
			_all_tiles.append(_grid[x][y])
	
	_selected_pos = selected_pos.duplicate()
	
	for pos in _selected_pos:
		_selected_tiles.append(_grid[pos.x][pos.y])
	
	_player = player
	_player_count = player_count
	
	for tile in valid_tiles:
		var pos = tile.get_grid_pos()
		_valid_tiles.append(_grid[pos.x][pos.y])
	
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
	#if _player != 0: EventBus.do_bot_turn.emit()
	return _player

func clear_valid_tiles() -> void:
	_valid_tiles.clear()

func add_valid_tile(tile: Tile) -> void:
	_valid_tiles.append(tile)

func get_valid_tiles() -> Array[Tile]:
	return _valid_tiles

func set_valid_tiles(new_valid_tiles: Array[Tile]) -> void:
	_valid_tiles = new_valid_tiles.duplicate()

func clone() -> GameState:
	var new_state = GameState.new()
	
	#var new_grid = _grid.duplicate(true)
	
	var new_grid: Array[Array] = _empty_grid
	
	for x in _grid_size.x:
		#new_grid.append([])
		for y in _grid_size.y:
			var tile = Tile.new()
			tile.init(self, Vector2(x, y))
			tile.set_walls(_grid[x][y].get_walls())
			new_grid[x][y] = tile
			#new_grid[x].append(tile)
	
	#var selected_pos = _selected_pos.duplicate()
	#var selected_pos = []
	#var selected_tiles: Array[Tile] = []
	
	#for pos in _selected_pos:
		#selected_pos.append(pos)
		#selected_tiles.append(new_grid[pos.x][pos.y])
	
	#var valid_tiles: Array[Tile] = []
	#
	#for tile in _valid_tiles:
		#var pos = tile.get_grid_pos()
		#valid_tiles.append(new_grid[pos.x][pos.y])
	
	new_state.init(new_grid, _grid_size, _selected_pos, _player, _player_count, _valid_tiles, _mode, _tile_size)
	
	return new_state

func try_place_wall_on_side(side: int) -> bool:
	var next_pos = get_player_selected_pos() + _side_dirs[side]
	#if next_pos.x < 0 or next_pos.y < 0 or next_pos.x > _grid_size.x - 1 or next_pos.y > _grid_size.y - 1: return false
	if not is_pos_in_grid(next_pos): return false
	
	if not get_player_selected_tile().place_wall_on_side(side):
		print("failed to place wall")
		return false

	get_tile(next_pos).place_wall_on_side(_get_opposite_side(side))

	calculate_scores()
	
	set_place_mode(MODE_COUNTER)

	return true

func try_place_counter_at_pos(pos: Vector2i) -> bool:
	if not tile_at_pos_valid(pos):
		print("failed to place counter")
		return false
	
	place_counter_at_pos(pos)
	
	set_place_mode(MODE_WALL)
	
	return true

func place_counter_at_pos(pos: Vector2i) -> void:
	if get_player_selected_tile(): get_player_selected_tile().remove_counter()

	var tile = get_tile(pos) as Tile
	tile.place_counter(get_player())
	select_player_tile(tile.get_grid_pos())

	EventBus.counter_placed.emit(tile.get_grid_pos())

func path_exists(from_player: int, to_player: int) -> Array[Tile]:
	#var tiles = _all_tiles.duplicate()
	var start_pos = get_selected_pos(from_player)
	
	#print("all tiles: ", len(tiles))
	
	var d = {}
	#var p = {}
	
	var unexplored = {}
	
	for tile in _all_tiles:
		d[tile] = 1000
		unexplored[tile] = null
		#var pos = tile.get_grid_pos()
		#d[tile] = abs(pos.x - start_pos.x) + abs(pos.y - start_pos.y)
		#p[tile] = null
	
	d[get_selected_tile(from_player)] = 0
	
	#var unexplored = tiles.duplicate()
	#var unexplored = [ get_selected_tile(from_player) ]
	#var to_explore = []
	
	#print("unexplored: ", len(unexplored))
	
	var shape: Array[Tile] = []
	
	var unexplored_sorted: Array[Tile] = [ get_selected_tile(from_player) ]
	
	while len(unexplored) != 0:
		var closest = unexplored.keys()[0]
		if len(unexplored_sorted) != 0:
			closest = unexplored_sorted[0]
			if closest == get_selected_tile(to_player) and d[closest] != 1000:
				#print("reached end: ", len(shape))
				return []
			
			unexplored_sorted.remove_at(0)
			unexplored.erase(closest)
		else:
			for tile in unexplored.keys():
				if d[tile] < d[closest]: closest = tile
			
			if closest == get_selected_tile(to_player) and d[closest] != 1000:
				#print("reached end: ", len(shape))
				return []
			
			unexplored.erase(closest)
		
		#print("closest distance: ", d[closest])
		
		shape.append(closest)
		
		for dir in _dir_sides.keys():
			var n_pos = closest.get_grid_pos() + dir
			if not is_pos_in_grid(n_pos): continue
			var n = get_tile(n_pos)
			if n not in unexplored: continue
			if not _can_move_to_from(n_pos, closest.get_grid_pos()): continue
			#if n in unexplored: continue
			#unexplored.append(n)
			#elif n_pos == get_selected_pos(to_player): return []
			
			#if n_pos == get_selected_pos(to_player):
				#print("can move from ", closest.get_grid_pos(), " to ", get_selected_pos(to_player))
			
			var new_dist = d[closest] + 1
			
			if new_dist < d[n]:
				d[n] = new_dist
				
				if len(unexplored_sorted) == 0:
					unexplored_sorted.append(n)
				else:
					var inserted = false
					for i in range(len(unexplored_sorted)):
						if d[n] > d[unexplored_sorted[i]]:
							unexplored_sorted.insert(i, n)
							inserted = true
							break
					if not inserted:
						unexplored_sorted.append(n)
				#p[n] = closest
	
	#if get_selected_tile(to_player) in shape: return []
	
	#print(len(shape))
	return shape

func calculate_scores() -> void:
	var shape1 = path_exists(_player, -_player + 1)
	if len(shape1) == 0:
		_score = [0, 0]
		#print("0s score")
		return
	
	var shape2 = path_exists(_player, -_player + 1)
	
	_score = [0, 0]
	_score[_player] = len(shape1)
	_score[-_player + 1] = len(shape2)
	
	return
	
	#var shapes = []
	#
	#for player in range(get_player_count()):
		#var tile = get_selected_tile(player)
		#var shape = { tile: null }
		##var checked = []
		#var checked = {}
	#
		#for from_tile in shape:
			#if from_tile in checked: continue
			##checked.append(from_tile)
			#checked[from_tile] = null
			#for dir in _dir_sides.keys():
				#var to_pos = from_tile.get_grid_pos() + dir
				#if not _can_move_to_from(to_pos, from_tile.get_grid_pos()): continue
				#if get_selected_pos(-player + 1) == to_pos:
					#_score = []
					#return
				#
				#var to = get_tile(to_pos)
				#
				#if not is_pos_in_grid(to_pos): continue
				#if to in shape: continue
				##shape.append(get_tile(to_pos))
				#shape[to] = null
	#
		#if len(shape) > _grid_size.x * _grid_size.y / 2:
			#_score = [0, 0]
			#_score[player] = 48
			#_score[-player + 1] = 1
			#return
		#
		#shapes.append(shape)
	#
	#_score = []
	##print(len(shapes), " shapes:")
	#for shape in shapes:
		##print("\t", len(shape))f
		#_score.append(len(shape))
	##print()
	#
	#if len(shapes) != get_player_count(): _score.clear()

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
			#print("next player")
			
			set_valid_tiles(find_valid_tiles(_player))
			
			EventBus.mode_changed.emit(MODE_COUNTER)
			
		MODE_WALL:
			EventBus.mode_changed.emit(MODE_WALL)

func _can_move_to_from(to_pos: Vector2i, from_pos: Vector2i) -> bool:
	if to_pos == from_pos: return true
	if not is_pos_in_grid(to_pos): return false
	if not is_pos_in_grid(from_pos): return false
	
	var dir = to_pos - from_pos
	if dir.length() > 1: return false
	#if dir.x != 0 and dir.y != 0: return false
	#if abs(dir.x) > 1 or abs(dir.y) > 1: return false
	
	#var side = _dir_sides[dir]
	
	#var to = get_tile(to_pos)
	#if to.has_wall_on_side(_get_opposite_side(side)): return false
	
	#var from = get_tile(from_pos)
	
	return not get_tile(from_pos).has_wall_on_side(_dir_sides[dir])

func find_valid_tiles(player: int) -> Array[Tile]:
	if not get_selected_tile(player): return []
	clear_valid_tiles()
	add_valid_tile(get_selected_tile(player))
	
	var new_valid_tiles: Array[Tile] = []
	
	var player_pos = get_selected_pos(player)
	var check_valid = Main._valid_from_pos[player_pos]
	var checked = {}
	
	for pos in check_valid:
		if pos == get_selected_pos(-player + 1):
			checked[pos] = null
			continue
		if _can_move_to_from(pos, player_pos):
			new_valid_tiles.append(_grid[pos.x][pos.y])
			#checked.append(pos)
			checked[pos] = null
	
	for pos in check_valid:
		if pos in checked: continue
		for tile in new_valid_tiles.duplicate():
			if _can_move_to_from(pos, tile.get_grid_pos()):
				new_valid_tiles.append(_grid[pos.x][pos.y])
	
	#var checked = []
	#
	#for i in range(2):
		#for from_tile in get_valid_tiles():
			#if from_tile in checked: continue
			#checked.append(from_tile)
			#for dir in _dir_sides.keys():
				#var to_pos = from_tile.get_grid_pos() + dir
				#if _can_move_to_from(to_pos, from_tile.get_grid_pos()):
					#var to = get_tile(to_pos)
					#if to in new_valid_tiles: continue
					#
					#if not tile_selected(to) or to == get_player_selected_tile():
						#new_valid_tiles.append(to)
		#set_valid_tiles(new_valid_tiles)
	#set_valid_tiles(new_valid_tiles)
	return new_valid_tiles

func get_valid_spaces(player: int) -> Array[Tile]:
	if not get_selected_tile(player): return []
	
	var valid_tiles: Array[Tile] = [ get_selected_tile(player) ]
	var new_valid_tiles = {}
	var checked = []
	
	for i in range(2):
		for from_tile in valid_tiles:
			if from_tile in checked: continue
			checked.append(from_tile)
			for dir in _dir_sides.keys():
				var to_pos = from_tile.get_grid_pos() + dir
				if _can_move_to_from(to_pos, from_tile.get_grid_pos()):
					var to = get_tile(to_pos)
					if to in new_valid_tiles: continue
					
					if not tile_selected(to) or to == get_selected_tile(player):
						new_valid_tiles[to] = null
		valid_tiles = new_valid_tiles.keys()
	
	#print(len(valid_tiles))
	
	return valid_tiles

func set_grid_size(grid_size: Vector2i) -> void:
	_grid_size = grid_size

func set_tile_size(tile_size: float) -> void:
	_tile_size = tile_size

func get_scores() -> Array[int]:
	return _score

func get_player_score(player: int) -> float:
	calculate_scores()
	if _score[player] > _score[-player + 1]: return 1
	return 0

func get_actions() -> Array[Action]:
	#set_valid_tiles(find_valid_tiles(_player))
	
	var actions: Array[Action] = []
	
	for tile in _valid_tiles:
		for side in _side_dirs.keys():
			if tile.has_wall_on_side(side): continue
			if not tile.can_place_wall_on_side(side): continue
			
			var action = Action.new()
			
			action.init(tile.get_grid_pos(), side)
			actions.append(action)
	
	return actions

func ended() -> bool:
	return len(_score) != 0 and _score[0] != 0

func get_grid_size() -> Vector2i:
	return _grid_size
