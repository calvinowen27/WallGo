extends Node2D

@export var _grid_size: Vector2i
@export var _tile_scene: PackedScene
@export var _tile_size: float = 16

@onready var _center: Vector2i = _grid_size * _tile_size / 2 - Vector2(_tile_size / 2, _tile_size / 2)
@onready var _camera: Camera2D = %Camera2D

#var _selected_tile: Tile
#var _selected_pos: Vector2i
var _selected_tiles: Array[Tile] = []
var _selected_pos: Array[Vector2i] = []
var _scores: Array[int] = []
var _player: int = 0
@export var _player_count: int = 2

var _grid: Array[Array]

var _valid_tiles: Array

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

func _ready() -> void:
	_camera.position = _center

	$WallButtons.size = Vector2(_tile_size, _tile_size)

	for x in range(_grid_size.x):
		_grid.append([])
		for y in range(_grid_size.y):
			var tile = _tile_scene.instantiate()
			tile.init(self, Vector2(x, y), _tile_size)
			$Tiles.add_child(tile)
			tile.position = Vector2(x, y) * tile.get_effective_size()
			_grid[x].append(tile)
	
	for i in range(_player_count):
		_selected_tiles.append(null)
		_selected_pos.append(Vector2i.ZERO)
		_scores.append(0)
	
	for i in range(_player_count):
		place_counter_at_pos(_grid_size / 2 + Vector2i(i, i))
		_set_place_mode(MODE_COUNTER)
	
	#place_counter_at_pos(_grid_size / 2 + Vector2i(2, 2))
	#_set_place_mode(MODE_COUNTER)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("click"):
		var mouse_pos = get_global_mouse_position() + Vector2(_tile_size / 2, _tile_size / 2)
		var idx = Vector2i(clamp(mouse_pos.x / _tile_size, 0, _grid_size.x - 1), clamp(mouse_pos.y / _tile_size, 0, _grid_size.y - 1))

		if _mode == MODE_COUNTER:
			if try_place_counter_at_pos(idx):
				_set_place_mode(MODE_WALL)

func try_place_wall_on_side(side: int) -> bool:
	var next_pos = _selected_pos[_player] + _side_dirs[side]
	if next_pos.x < 0 or next_pos.y < 0 or next_pos.x > _grid_size.x - 1 or next_pos.y > _grid_size.y - 1: return false
	
	if not _selected_tiles[_player].place_wall_on_side(side): return false

	_grid[next_pos.x][next_pos.y].place_wall_on_side(_get_opposite_side(side))

	_set_place_mode(MODE_COUNTER)

	return true

func try_place_counter_at_pos(pos: Vector2i) -> bool:
	if _grid[pos.x][pos.y] not in _valid_tiles: return false
	
	place_counter_at_pos(pos)
	
	return true

func place_counter_at_pos(pos: Vector2i) -> void:
	if _selected_tiles[_player]: _selected_tiles[_player].remove_counter()

	var tile = _grid[pos.x][pos.y] as Tile
	tile.place_counter(_player)
	_selected_tiles[_player] = tile
	_selected_pos[_player] = pos

	$WallButtons.position = _selected_tiles[_player].position - Vector2(_tile_size, _tile_size) / 2

	calculate_scores()

func calculate_scores() -> void:
	pass

	

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
	_mode = mode
	match mode:
		MODE_COUNTER:
			_player = (_player + 1) % _player_count
			
			$WallButtons/WallLeft.show()
			$WallButtons/WallRight.show()
			$WallButtons/WallTop.show()
			$WallButtons/WallBottom.show()
			
			$WallButtons.hide()
			highlight_valid_tiles()
			
		MODE_WALL:
			$WallButtons.show()
			unhighlight_tiles()
			
			if _selected_pos[_player].x == 0 or _selected_tiles[_player].has_wall_on_side(SIDE_LEFT):
				$WallButtons/WallLeft.hide()
			if _selected_pos[_player].x == _grid_size.x - 1 or _selected_tiles[_player].has_wall_on_side(SIDE_RIGHT):
				$WallButtons/WallRight.hide()
			if _selected_pos[_player].y == 0 or _selected_tiles[_player].has_wall_on_side(SIDE_TOP):
				$WallButtons/WallTop.hide()
			if _selected_pos[_player].y == _grid_size.y - 1 or _selected_tiles[_player].has_wall_on_side(SIDE_BOTTOM):
				$WallButtons/WallBottom.hide()

func _can_move_to_from(to_pos: Vector2i, from_pos: Vector2i) -> bool:
	var dir = to_pos - from_pos
	if dir.length() > 1: return false
	if to_pos.x > _grid_size.x - 1 or to_pos.y > _grid_size.y - 1: return false
	if to_pos.x < 0 or to_pos.y < 0: return false
	if from_pos.x > _grid_size.x - 1 or from_pos.y > _grid_size.y - 1: return false
	if from_pos.x < 0 or from_pos.y < 0: return false
	
	var to = _grid[to_pos.x][to_pos.y]
	
	if to in _selected_tiles and not to == _selected_tiles[_player]: return false
	
	var from = _grid[from_pos.x][from_pos.y]
	
	var side = _dir_sides[dir]
	
	return not from.has_wall_on_side(side) and not to.has_wall_on_side(_get_opposite_side(side))

func highlight_valid_tiles() -> void:
	if not _selected_tiles[_player]: return
	_valid_tiles = [ _selected_tiles[_player] ]
	
	var new_valid_tiles = []
	var checked = []
	
	for i in range(2):
		for from_tile in _valid_tiles:
			if from_tile in checked: continue
			checked.append(from_tile)
			for dir in _dir_sides.keys():
				var to_pos = from_tile.get_grid_pos() + dir
				if _can_move_to_from(to_pos, from_tile.get_grid_pos()):
					new_valid_tiles.append(_grid[to_pos.x][to_pos.y])
		_valid_tiles = new_valid_tiles.duplicate()
	
	for tile in _valid_tiles:
		tile.highlight()

func unhighlight_tiles() -> void:
	for tile in _valid_tiles:
		tile.unhighlight()

func get_grid_size() -> Vector2i:
	return _grid_size
