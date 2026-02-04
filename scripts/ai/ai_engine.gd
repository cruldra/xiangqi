class_name AIEngine
extends Object

## 简易AI引擎
##
## 使用 Minimax 算法 + Alpha-Beta 剪枝来寻找最佳走法。

const MAX_DEPTH = 3 # 搜索深度 (奇数通常更好)
const INF = 999999

## 获取最佳走法
## @param board_logic: 当前棋盘状态
## @param side: AI 执红还是执黑
## @return Dictionary: {"from": Vector2i, "to": Vector2i} 或 null
static func get_best_move(board_logic: BoardLogic, side: Constants.Side) -> Dictionary:
	var best_score = -INF
	var best_move = null
	
	# 获取所有合法走法
	var moves = MoveGenerator.get_all_legal_moves(board_logic, side)
	
	# 简单的走法排序优化：优先考虑吃子 (可以大幅提高剪枝效率)
	# 这里暂时不做复杂排序，直接搜
	
	for move in moves:
		# 模拟移动
		var captured = board_logic.move_piece(move["from"], move["to"])
		
		# 递归搜索 (对方回合，取极小值)
		var score = _minimax(board_logic, MAX_DEPTH - 1, -INF, INF, false, side)
		
		# 撤销移动
		board_logic.undo_last_move()
		
		if score > best_score:
			best_score = score
			best_move = move
			
	return best_move

## Minimax 递归函数
## @param is_maximizing: 是否是 AI 方 (最大化层)
static func _minimax(board_logic: BoardLogic, depth: int, alpha: int, beta: int, is_maximizing: bool, ai_side: Constants.Side) -> int:
	# 1. 终止条件：深度为0 或 游戏结束
	if depth == 0:
		var score = Evaluator.evaluate(board_logic)
		# 评估函数返回的是 Red - Black
		# 如果 AI 是 Red，直接用 score；如果 AI 是 Black，用 -score
		return score if ai_side == Constants.Side.RED else -score
		
	# TODO: 检测是否被绝杀/将死 (增加极大/极小分)
	
	var current_side = board_logic.current_turn
	var moves = MoveGenerator.get_all_legal_moves(board_logic, current_side)
	
	if moves.is_empty():
		# 无棋可走 (困毙/绝杀)
		# 如果是 AI 回合无棋可走 -> 输了 (-INF)
		# 如果是 对方 回合无棋可走 -> 赢了 (INF)
		return -INF if is_maximizing else INF
	
	if is_maximizing:
		var max_eval = -INF
		for move in moves:
			board_logic.move_piece(move["from"], move["to"])
			var eval = _minimax(board_logic, depth - 1, alpha, beta, false, ai_side)
			board_logic.undo_last_move()
			
			max_eval = max(max_eval, eval)
			alpha = max(alpha, eval)
			if beta <= alpha:
				break # Beta 剪枝
		return max_eval
	else:
		var min_eval = INF
		for move in moves:
			board_logic.move_piece(move["from"], move["to"])
			var eval = _minimax(board_logic, depth - 1, alpha, beta, true, ai_side)
			board_logic.undo_last_move()
			
			min_eval = min(min_eval, eval)
			beta = min(beta, eval)
			if beta <= alpha:
				break # Alpha 剪枝
		return min_eval
