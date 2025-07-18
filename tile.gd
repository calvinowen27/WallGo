extends Node

class_name Tile

var _controller: Node

var _pos: Vector2i
var _walls: Dictionary

var _has_counter: int = -1

var _tile_display: Sprite2D

enum {
	SIDE_TOP,
	SIDE_BOTTOM,
	SIDE_RIGHT,
	SIDE_LEFT
}

func init(controller: Node, pos: Vector2i, tile_display: Sprite2D = null) -> void:
	_controller = controller
	_pos = pos
	_tile_display = tile_display
	
	_walls = {
		SIDE_LEFT: false,
		SIDE_RIGHT: false,
		SIDE_TOP: false,
		SIDE_BOTTOM : false
	}

func place_counter(player: int) -> void:
	_has_counter = player
	
	if _tile_display: _tile_display.place_counter(player)

func remove_counter() -> void:
	_has_counter = -1
	
	if _tile_display: _tile_display.remove_counter()

func place_wall_on_side(side: int) -> bool:
	if side not in _walls.keys(): return false
	
	_walls[side] = true
	if _tile_display: _tile_display.place_wall_on_side(side)
	
	return true

func has_wall_on_side(side: int) -> bool:
	return _walls[side]

func wall_count() -> int:
	var sum = 0
	for key in _walls.keys():
		if _walls[key]: sum += 1
	
	return sum

func has_wall_to_edge() -> bool:
	if has_wall_on_side(SIDE_LEFT) and (_pos.y == 0 or _pos.y == _controller.get_grid_size().y - 1): return true
	if has_wall_on_side(SIDE_RIGHT) and (_pos.y == 0 or _pos.y == _controller.get_grid_size().y - 1): return true
	if has_wall_on_side(SIDE_BOTTOM) and (_pos.x == 0 or _pos.x == _controller.get_grid_size().x - 1): return true
	if has_wall_on_side(SIDE_TOP) and (_pos.x == 0 or _pos.x == _controller.get_grid_size().x - 1): return true

	return false

func get_walls() -> Dictionary:
	return _walls

func get_grid_pos() -> Vector2i:
	return _pos

func get_display() -> Sprite2D:
	return _tile_display
