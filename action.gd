extends Node

class_name Action

var _next_pos: Vector2i
var _wall_side: int

var _key: String

var _parent: Action = null

func init(next_pos: Vector2i, wall_side: int) -> void:
	_next_pos = next_pos
	_wall_side = wall_side
	
	_key = "a(%d, %d)-%d" % [_next_pos.x, next_pos.y, _wall_side]

func key() -> String:
	return _key

func get_next_pos() -> Vector2i:
	return _next_pos

func get_wall_side() -> int:
	return _wall_side

func set_parent(parent: Action) -> void:
	_parent = parent

func is_wall_adjacent_to_tile(pos: Vector2i) -> bool:
	if pos.x != _next_pos.x and pos.y != _next_pos.y: return false
	
	if pos.y == _next_pos.y:
		if pos.x == _next_pos.x - 1 and _wall_side == SIDE_LEFT: return true
		if pos.x == _next_pos.x + 1 and _wall_side == SIDE_RIGHT: return true
	
	if pos.x == _next_pos.x:
		if pos.y == _next_pos.y - 1 and _wall_side == SIDE_BOTTOM: return true
		if pos.y == _next_pos.y + 1 and _wall_side == SIDE_TOP: return true
	
	return false
