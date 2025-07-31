extends Node

signal mode_changed(state: GameState, mode: int)
signal counter_placed(state: GameState, pos: Vector2i)
signal wall_placed(state: GameState, pos: Vector2i, side: int)
signal game_over(state: GameState)
signal do_bot_turn(state: GameState)
signal use_card(card: String)
signal invalidate_tile(state: GameState, pos: Vector2i)
