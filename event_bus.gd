extends Node

signal mode_changed(state: GameState, mode: int)
signal counter_placed(state: GameState, pos: Vector2)
signal wall_placed(state: GameState, side: int)
signal game_over(state: GameState)
signal do_bot_turn(state: GameState)
