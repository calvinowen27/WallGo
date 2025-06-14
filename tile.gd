extends Sprite2D

class_name Tile

@export var _highlight_color: Color

var _pos: Vector2i
var _walls: Dictionary

var _controller: Node2D

enum {
	SIDE_TOP,
	SIDE_BOTTOM,
	SIDE_RIGHT,
	SIDE_LEFT
}

func init(controller: Node2D, pos: Vector2, tile_size: float) -> void:
	_controller = controller
	_pos = pos
	set_size(tile_size)

	_walls = {
		SIDE_LEFT: false,
		SIDE_RIGHT: false,
		SIDE_TOP: false,
		SIDE_BOTTOM : false
	}

func place_counter(player: int) -> void:
	$Counter.visible = true
	
	if player == 1: $Counter.self_modulate = Color.BLUE
	else: $Counter.self_modulate = Color.WHITE

func remove_counter() -> void:
	$Counter.visible = false

func place_wall_on_side(side: int) -> bool:
	if side not in _walls.keys(): return false
	
	match side:
		SIDE_TOP: $WallTop.show()
		SIDE_BOTTOM: $WallBottom.show()
		SIDE_LEFT: $WallLeft.show()
		SIDE_RIGHT: $WallRight.show()
		_: return false
	
	_walls[side] = true
	
	return true

func has_wall_on_side(side: int) -> bool:
	return _walls[side]

func has_wall_to_edge() -> bool:
	if has_wall_on_side(SIDE_LEFT) and (_pos.y == 0 or _pos.y == _controller.get_grid_size().y - 1): return true
	if has_wall_on_side(SIDE_RIGHT) and (_pos.y == 0 or _pos.y == _controller.get_grid_size().y - 1): return true
	if has_wall_on_side(SIDE_BOTTOM) and (_pos.x == 0 or _pos.x == _controller.get_grid_size().x - 1): return true
	if has_wall_on_side(SIDE_TOP) and (_pos.x == 0 or _pos.x == _controller.get_grid_size().x - 1): return true

	return false

func get_walls() -> Dictionary:
	return _walls

func get_texture_dims() -> Vector2:
	return texture.get_size()

func set_size(size: float) -> void:
	scale = Vector2(size, size) / texture.get_size()

func get_effective_size() -> Vector2:
	return texture.get_size() * scale

func get_grid_pos() -> Vector2i:
	return _pos

func highlight() -> void:
	self_modulate = _highlight_color

func unhighlight() -> void:
	self_modulate = Color.WHITE
