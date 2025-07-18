extends Node

class_name TreeNode

var _parent: TreeNode = null

var _children: Dictionary
var _results: Array[int]

var _action: Action

func init(parent: TreeNode = null, key: String = "") -> void:
	_parent = parent
	
	_children = {}

func avg_score() -> int:
	var sum = 0
	for result in _results:
		sum += result
	
	return sum / len(_results)

func step(state: GameState) -> void:
	print("STEP")
	select(state)

func get_best(state: GameState) -> Action:
	var actions = state.get_actions()
	
	var max_score = 0
	var best = actions[0]
	
	for action in actions:
		if action.key() not in _children.keys(): continue
		var avg_score = _children[action.key()].avg_score()
		if avg_score > max_score:
			max_score = avg_score
			best = action
	
	return best

func select(state: GameState) -> void:
	print("SELECT")
	
	var actions = state.get_actions()
	if len(actions) == 0: return
	
	var unexplored: Array[Action] = []
	
	for action in actions:
		if action.key() not in _children.keys():
			unexplored.append(action)
	
	if len(unexplored) != 0:
		expand(state, unexplored)
	else:
		var best_action = select_action(actions)
		
		var new_state = state.clone()
		new_state.try_place_counter_at_pos(best_action.get_next_pos())
		new_state.try_place_wall_on_side(best_action.get_wall_side())
		_children[best_action.key()].select(new_state)

func select_action(actions: Array[Action]) -> Action:
	return actions[randi_range(0, len(actions) - 1)]

func calculate_action_value(action: Action) -> void:
	pass

func expand(state: GameState, avail_actions: Array[Action]) -> void:
	print("EXPAND")
	
	var action = avail_actions[randi_range(0, len(avail_actions) - 1)]
	var new_child = TreeNode.new()
	new_child.init(self, action.key())
	
	_children[action.key()] = new_child
	var new_state = state.clone()
	new_state.try_place_counter_at_pos(action.get_next_pos())
	new_state.try_place_wall_on_side(action.get_wall_side())
	new_child.rollout(new_state)

func rollout(state: GameState) -> void:
	print("ROLLOUT")
	
	var count = 0
	while not state.ended() and count < 100:
		var actions = state.get_actions()
		var action = actions[randi_range(0, len(actions) - 1)]
		state = state.clone()
		state.try_place_counter_at_pos(action.get_next_pos())
		state.try_place_wall_on_side(action.get_wall_side())
		count += 1
		print(count)
	
	backpropagate(score(state))

func backpropagate(result: int) -> void:
	print("BACKPROPAGATE")
	
	_results.append(result)
	if _parent: _parent.backpropagate(result)

func score(state: GameState) -> int:
	print("SCORE")
	
	return state.get_player_score(1)
