extends Sprite2D

@export var _highlight_color: Color

var _tile: Tile

enum {
	SIDE_TOP,
	SIDE_BOTTOM,
	SIDE_LEFT,
	SIDE_RIGHT
}

func init(controller, pos: Vector2, tile_size: float) -> void:
	_tile = Tile.new()
	_tile.init(controller, pos, self)
	
	set_size(tile_size)
	
func place_counter(player: int) -> void:
	$Counter.visible = true
	
	if player == 1: $Counter.self_modulate = Color.BLUE
	else: $Counter.self_modulate = Color.WHITE

func remove_counter() -> void:
	$Counter.visible = false

func place_wall_on_side(side: int) -> void:
	match side:
		SIDE_TOP: $WallTop.show()
		SIDE_BOTTOM: $WallBottom.show()
		SIDE_LEFT: $WallLeft.show()
		SIDE_RIGHT: $WallRight.show()

func destroy_wall_on_side(side: int) -> void:
	match side:
		SIDE_TOP: $WallTop.hide()
		SIDE_BOTTOM: $WallBottom.hide()
		SIDE_LEFT: $WallLeft.hide()
		SIDE_RIGHT: $WallRight.hide()

func reset_walls() -> void:
	$WallTop.hide()
	$WallBottom.hide()
	$WallLeft.hide()
	$WallRight.hide()

func invalidate() -> void:
	self_modulate = Color.ORANGE_RED

func has_wall_on_side(side: int) -> bool:
	return _tile.has_wall_on_side(side)

func has_wall_to_edge() -> bool:
	return _tile.has_wall_on_edge()

func get_walls() -> Dictionary:
	return _tile.get_walls()

func get_texture_dims() -> Vector2:
	return texture.get_size()

func set_size(size: float) -> void:
	if not texture: return
	scale = Vector2(size, size) / texture.get_size()

func get_effective_size() -> Vector2:
	if not texture: return Vector2.ZERO
	return texture.get_size() * scale

func get_grid_pos() -> Vector2i:
	return _tile.get_grid_pos()

func highlight() -> void:
	self_modulate = _highlight_color

func unhighlight() -> void:
	self_modulate = Color.WHITE

func get_tile() -> Tile:
	return _tile
