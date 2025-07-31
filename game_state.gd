extends Node

class_name GameState

const PLAYER_COUNT = 2

const SIDES: Array = [ SIDE_TOP, SIDE_BOTTOM, SIDE_LEFT, SIDE_RIGHT ]
const DIRS: Array = [ Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0) ]

const SIDE_FROM_DIR: Dictionary = {
	Vector2i(0, -1): SIDE_TOP,
	Vector2i(0, 1): SIDE_BOTTOM,
	Vector2i(-1, 0): SIDE_LEFT,
	Vector2i(1, 0): SIDE_RIGHT
}

enum {
	SIDE_TOP,
	SIDE_BOTTOM,
	SIDE_LEFT,
	SIDE_RIGHT
}

enum {
	PLACE_MODE_COUNTER,
	PLACE_MODE_WALL
}

var _selected_pos: Array[Vector2i]
var _prev_selected_pos: Array[Vector2i]
var _curr_player: int

var _grid: Dictionary
var _grid_size: Vector2i

var _invalid_tiles: Dictionary

var _valid_pos: Array[Vector2i]

var _place_mode: int

var _score: Array[int]

var _board_card: String

func init(grid: Dictionary, grid_size: Vector2i, selected_pos: Array[Vector2i] = [Vector2i.ZERO, Vector2i.ZERO], curr_player: int = 0, place_mode: int = PLACE_MODE_COUNTER, valid_pos: Array[Vector2i] = [], board_card: String = "") -> void:
	_grid = grid.duplicate(true)
	_grid_size = grid_size
	
	_prev_selected_pos = [ Vector2i.ZERO, Vector2i.ZERO ]
	_selected_pos = selected_pos.duplicate(true)
	_curr_player = curr_player
	
	_place_mode = place_mode
	_valid_pos = valid_pos.duplicate(true)
	
	_board_card = board_card

func clone() -> GameState:
	var new_state = GameState.new()
	
	new_state.init(_grid, _grid_size, _selected_pos, _curr_player, _place_mode, _valid_pos, _board_card)
	
	return new_state

func try_place_wall_on_side(side: int) -> bool:
	var player_pos = get_curr_player_selected_pos()
	
	# check if wall on side
	if player_pos in _grid and _grid[player_pos][side]: return false
	
	# check if on edge
	if is_edge_on_pos_side(player_pos, side): return false
	
	# pos not in grid, initialize with false values for walls
	if player_pos not in _grid:
		_grid[player_pos] = [ false, false, false, false ]
	
	var dir = DIRS[side]
	var side_pos = player_pos + dir
	if side_pos not in _grid:
		_grid[side_pos] = [ false, false, false, false ]
	
	var opp_side = _get_opposite_side(side)
	
	#print("placed wall on ", side, " side at pos: ", player_pos)
	#print("placed wall on ", opp_side, " side at pos: ", side_pos)
	
	# place the wall
	_grid[player_pos][side] = true
	
	EventBus.wall_placed.emit(self, player_pos, side)
	
	_grid[side_pos][opp_side] = true
	
	EventBus.wall_placed.emit(self, side_pos, opp_side)
	
	calculate_scores()
	
	next_player()
	
	return true

func try_place_counter_at_pos(pos: Vector2i) -> bool:
	# check if pos out of grid or invalid
	if not is_pos_in_grid(pos): return false
	if len(_valid_pos) != 0 and pos not in _valid_pos: return false
	
	# place the counter
	_prev_selected_pos[_curr_player] = _selected_pos[_curr_player]
	_selected_pos[_curr_player] = pos
	
	if pos not in _grid:
		_grid[pos] = [ false, false, false, false ]
	
	EventBus.counter_placed.emit(self, pos)
	
	set_place_mode(PLACE_MODE_WALL)
	
	return true

func set_board_card(board_card: String) -> void:
	_board_card = board_card
	print("board card set to ", _board_card)

# ========== #
#	GETTERS  #
# ========== #

func get_selected_pos(player: int) -> Vector2i:
	return _selected_pos[player]

func get_curr_player_selected_pos() -> Vector2i:
	return get_selected_pos(_curr_player)

func get_prev_selected_pos(player: int) -> Vector2i:
	return _prev_selected_pos[player]

func get_curr_player_prev_selected_pos() -> Vector2i:
	return get_prev_selected_pos(_curr_player)

func tile_at_pos_selected(pos: Vector2i) -> bool:
	return pos in _selected_pos

func tile_at_pos_valid(pos: Vector2i) -> bool:
	return pos in _valid_pos

func get_curr_player() -> int:
	return _curr_player

func get_scores() -> Array[int]:
	#print(_score)
	return _score

func get_place_mode() -> int:
	return _place_mode

func get_valid_pos() -> Array[Vector2i]:
	return _valid_pos

func tile_at_pos_has_wall_on_side(pos: Vector2i, side: int) -> bool:
	#print("pos ", pos, " has wall on side", side, ": ", pos in _grid and _grid[pos][side])
	return pos in _grid and _grid[pos][side]

func _get_opposite_side(side: int) -> int:
	match side:
		SIDE_TOP: return SIDE_BOTTOM
		SIDE_BOTTOM: return SIDE_TOP
		SIDE_LEFT: return SIDE_RIGHT
		SIDE_RIGHT: return SIDE_LEFT
	
	return -1

func is_edge_on_pos_side(pos: Vector2i, side: int) -> bool:
	match side:
		SIDE_LEFT:
			return pos.x == 0
		SIDE_RIGHT:
			return pos.x == _grid_size.x - 1
		SIDE_TOP:
			return pos.y == 0
		SIDE_BOTTOM:
			return pos.y == _grid_size.y - 1
		_:
			return true

func is_pos_in_grid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < _grid_size.x and pos.y >= 0 and pos.y < _grid_size.y

func find_shape(from_player: int, to_player: int) -> int:
	var start_pos = get_selected_pos(from_player)
	
	var d = {}
	var unexplored = {}
	#var unexplored = []
	
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			var pos = Vector2i(x, y)
			d[pos] = 1000
			#unexplored.append(pos)
			unexplored[pos] = null

	d[get_selected_pos(from_player)] = 0
	
	var shape_size = 0
	
	while len(unexplored.keys()) != 0:
		var closest = unexplored.keys()[0]
		
		for pos in unexplored.keys():
			if d[pos] < d[closest]: closest = pos
		
		if d[closest] == 1000: break
		
		if closest == get_selected_pos(to_player):
			#print("reached end: ", len(shape))
			return 0
			
		unexplored.erase(closest)
		
		#shape.append(closest)
		
		shape_size += 1
		
		for dir in DIRS:
			var n = closest + dir
			if not is_pos_in_grid(n): continue
			if n not in unexplored: continue
			if not _can_move_to_from(n, closest): continue
			
			#unexplored.append(n)

			var new_dist = d[closest] + 1
			
			if new_dist < d[n]:
				d[n] = new_dist
				
	return shape_size

func find_shape2(from_player: int, to_player: int) -> int:
	var start_pos = get_selected_pos(from_player)
	var end_pos = get_selected_pos(to_player)
	
	var shape_size: int = 0
	
	var unexplored = [ start_pos ]
	
	while len(unexplored) != 0:
		var curr = unexplored[0]
		
		unexplored.remove_at(0)
		
		for dir in DIRS:
			var n = curr + dir
			if not is_pos_in_grid(n): continue
			if not _can_move_to_from(n, curr): continue
			if n in unexplored: continue
			
			if n == end_pos: return 0
			
			unexplored.append(n)
			shape_size += 1
	
	print(shape_size)
	return shape_size

func _can_move_to_from(to_pos: Vector2i, from_pos: Vector2i) -> bool:
	if to_pos == from_pos: return true
	if not is_pos_in_grid(to_pos): return false
	if not is_pos_in_grid(from_pos): return false
	if to_pos in _invalid_tiles: return false
	
	var dir = to_pos - from_pos
	if dir.length() > 1: return false
	
	if to_pos not in _grid: return true
	if from_pos not in _grid: return true
	
	return not _grid[from_pos][SIDE_FROM_DIR[dir]]

func calculate_scores() -> void:
	var shape0_size = find_shape(0, 1)
	if shape0_size == 0:
		_score = [0, 0]
		return
	
	#print("path doesn't exist:")
	#var shape1 = path_exists(_curr_player, -_curr_player + 1)
	var shape1_size = find_shape(1, 0)
	#var shape1 = path_exists(1, 0)
	
	_score = [shape0_size, shape1_size]
	#print("\t", _score)
	
	return

func find_valid_pos(player: int, jump: bool = false, extra_space: bool = false) -> Array[Vector2i]:
	var new_valid_pos: Array[Vector2i] = []
	
	var player_pos = get_selected_pos(player)
	var check_valid = Main._valid_from_pos[player_pos]
	var checked = {}
	
	for pos in check_valid:
		if pos != player_pos and pos in _selected_pos: continue
		if not is_pos_in_grid(pos): continue
		
		if jump or _can_move_to_from(pos, player_pos):
			new_valid_pos.append(pos)
			continue
		
		for dir in DIRS:
			var n = player_pos + dir
			if n != player_pos and n in _selected_pos: continue
			if not is_pos_in_grid(n): continue
			
			if _can_move_to_from(n, player_pos) and _can_move_to_from(pos, n):
				new_valid_pos.append(pos)
				break
	
	if extra_space:
		for pos in new_valid_pos.duplicate():
			for dir in DIRS:
				var n = pos + dir
				if not is_pos_in_grid(n): continue
				if n != player_pos and n in _selected_pos: continue
				
				if _can_move_to_from(n, pos):
					new_valid_pos.append(n)
			
	
	return new_valid_pos

func get_player_score(player: int) -> Array:
	calculate_scores()
	if _score[player] > _score[-player + 1]:
		#print("bot wins this state")
		return [ 1, _score[player] ]
	
	#return _score[player] / 49
	#return [ _score[player] / 49, _score[player] ]
	return [ 0, _score[player] ]

func get_actions() -> Array[Action]:
	#_valid_pos = find_valid_pos(_curr_player)
	var actions: Array[Action] = []
	
	for pos in _valid_pos:
		for side in SIDES:
			if pos in _grid and _grid[pos][side]: continue
			if is_edge_on_pos_side(pos, side): continue
			
			var action = Action.new()
			
			action.init(pos, side)
			actions.append(action)
	
	return actions

func ended() -> bool:
	return len(_score) != 0 and _score[0] != 0

# ========== #
#	SETTERS  #
# ========== #

func set_place_mode(mode: int) -> void:
	_place_mode = mode
	
	match mode:
		PLACE_MODE_COUNTER:
			_valid_pos = find_valid_pos(_curr_player)
			
			match _board_card:
				"flood":
					var pos = Vector2i(randi_range(0, _grid_size.x - 1), randi_range(0, _grid_size.y - 1))
					while pos in _selected_pos:
						pos = Vector2i(randi_range(0, _grid_size.x - 1), randi_range(0, _grid_size.y - 1))
					
					_invalid_tiles[pos] = null
					EventBus.invalidate_tile.emit(self, pos)
			
			EventBus.mode_changed.emit(self, PLACE_MODE_COUNTER)
			
		PLACE_MODE_WALL:
			match _board_card:
				"lava step":
					var pos = get_curr_player_prev_selected_pos()
					if pos != get_curr_player_selected_pos():
						#print("lava stepping ", pos)
						_invalid_tiles[pos] = null
						EventBus.invalidate_tile.emit(self, pos)
			
			EventBus.mode_changed.emit(self, PLACE_MODE_WALL)

func destroy_wall_on_side(side: int) -> void:
	var pos = get_curr_player_selected_pos()
	
	_grid[pos][side] = false
	_grid[pos + DIRS[side]][_get_opposite_side(side)] = false

func select_tile(player: int, pos: Vector2i) -> void:
	_selected_pos[player] = pos

func select_curr_player_tile(pos: Vector2i) -> void:
	select_tile(_curr_player, pos)

func next_player() -> int:
	_curr_player = (_curr_player + 1) % PLAYER_COUNT
	
	_valid_pos.clear()
	
	set_place_mode(PLACE_MODE_COUNTER)
	
	return _curr_player
