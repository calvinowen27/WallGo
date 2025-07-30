extends Node

class_name TreeNode

var _parent: TreeNode = null

var _children: Dictionary
var _results: Array[float]

var _action: Action

var _score = []

var _depth = 0

func init(parent: TreeNode = null, key: String = "") -> void:
	_parent = parent
	
	if parent:
		_depth = _parent._depth + 1
	
	_children = {}

func avg_score() -> float:
	#return len(_results)
	var sum = 0
	for result in _results:
		sum += result
	
	return float(sum) / len(_results)

func step(state: GameState) -> void:
	#print("STEP")
	select(state)

func get_best(state: GameState) -> Action:
	var actions = state.get_actions()
	
	var max_score = 0
	#var max_spaces = 0
	var min_depth = 1000
	var best = actions[0]
	
	for action in actions:
		if action.key() not in _children.keys(): continue
		var avg_score = _children[action.key()].avg_score()
		#var avg_score = len(_children[action.key()]._results)
		print("action score is ", avg_score)
		if avg_score > max_score:
			max_score = avg_score
			#max_spaces = _children[action.key()]._score[1]
			min_depth = _children[action.key()]._score[1]
			best = action
		elif avg_score == max_score:
			if _children[action.key()]._score[1] < min_depth:
				max_score = avg_score
				print("tie breaker, ", min_depth, " < ", _children[action.key()]._score[1])
				#max_spaces = _children[action.key()]._score[1]
				min_depth = _children[action.key()]._score[1]
				best = action
	
	print("best score is ", max_score)
	print(best.key())
	#print()
	#for y in state.get_grid_size().x:
		#var line = ""
		#for x in state.get_grid_size().y:
			#line += "%d " % state.get_tile(Vector2i(x, y)).wall_count()
		#print(line)
	#print()
			
	return best

func select(state: GameState) -> void:
	#print("SELECT")
	
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
	#print("``````````````````````SELECT ACTION")
	#var values = []
	var max = 0
	var best = actions[0]
	
	for action in actions:
		var value = calculate_action_value(_children[action.key()])
		#max += value
		#values.append(max)
		if value > max:
			max = value
			best = action
		#print(max)
	
	return best
	
	#for value in values:
		#value /= max
	#
	#var r = randf()*max
	#var prev = 0
	#for i in range(len(values)):
		#if prev >= r and r < values[i]:
			#return actions[i]
		#prev += values[i]
	#
	#return actions[-1]

func calculate_action_value(child: TreeNode) -> float:
	#print("CALC ACTION VALUE")
	var score = avg_score()
	var value = score + 1.414 * sqrt(log(len(_results)) / len(child._results))
	return value

func expand(state: GameState, avail_actions: Array[Action]) -> void:
	#print("EXPAND")
	
	var action = avail_actions.pick_random()
	var new_child = TreeNode.new()
	new_child.init(self, action.key())
	
	_children[action.key()] = new_child
	var new_state = state.clone()
	new_state.try_place_counter_at_pos(action.get_next_pos())
	
	if not new_state.try_place_wall_on_side(action.get_wall_side()):
		print("failed to place wall in expand")
	
	new_child.rollout(new_state)

func rollout(state: GameState) -> void:
	#print("ROLLOUT")
	
	var count = 0
	while not state.ended() and count < 25:
		var actions = state.get_actions()
		if len(actions) == 0: break
		
		#var values = []
		#var player_pos = state.get_selected_pos(0)
		#
		#var max = 0
		#for action in actions:
			#var dist1 = (player_pos - action.get_next_pos()).length()
			#max += 2-dist1
			#if action.is_wall_adjacent_to_tile(player_pos):
				#max += 0.5
			#
			#values.append(max)
		
		var action = actions.pick_random()
		#print("hi")
		#var prev = 0
		#var r = randf()*max
		#for i in range(len(values)):
			#var value = values[i]
			#if prev <= r and r < value:
				#action = actions[i]
				#break
		
		state = state.clone()
		state.try_place_counter_at_pos(action.get_next_pos())
		state.try_place_wall_on_side(action.get_wall_side())
		count += 1
		#print(count)
	
	backpropagate(score(state))

func backpropagate(result: Array) -> void:
	#print("BACKPROPAGATE")
	
	_results.append(result[0])
	_score = result
	
	#print("appending ", result)
	if _parent: _parent.backpropagate(result)

func score(state: GameState) -> Array:
	#print("SCORE")
	
	#print("and score is ", state.get_player_score(1))
	
	#print()
	#for y in state.get_grid_size().x:
		#var line = ""
		#for x in state.get_grid_size().y:
			#line += "%d " % state.get_tile(Vector2i(x, y)).wall_count()
		#print(line)
	#print()
	
	#var score = state.get_player_score(1)
	#_score = [state.get_player_score(0), state.get_player_score(1)]
	#print(score)
	_score = state.get_player_score(1)
	_score[1] = _depth
	#_score[0] = pow(_score[0], 3) * 0.85
	
	#score = score * score * score
	#var score = pow(_score[0], 3)
	
	return _score
