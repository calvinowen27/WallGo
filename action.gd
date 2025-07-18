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
