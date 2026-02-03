class_name CheckDetector
extends Object

## 检查某方是否被将军
static func is_in_check(board_logic: BoardLogic, side: Constants.Side) -> bool:
	var general_pos = _find_general(board_logic, side)
	if general_pos == Vector2i(-1, -1):
		return false # 没找到帅/将（理论上不应发生）
	
	var opponent_side = Constants.Side.BLACK if side == Constants.Side.RED else Constants.Side.RED
	return is_position_attacked(board_logic, general_pos, opponent_side)

## 检查位置是否被某方攻击
static func is_position_attacked(board_logic: BoardLogic, pos: Vector2i, by_side: Constants.Side) -> bool:
	# 遍历攻击方的所有棋子
	for x in range(Constants.BOARD_COLS):
		for y in range(Constants.BOARD_ROWS):
			var p = board_logic.get_piece_at(Vector2i(x, y))
			if p and p.side == by_side:
				# 获取该棋子的合法攻击范围
				# 注意：这里使用 get_legal_moves，它是纯规则移动，不包含"不能送将"的判断，
				# 这正是我们需要用来判断"是否有威胁"的。
				var moves = MoveGenerator.get_legal_moves(board_logic, p.board_pos)
				if pos in moves:
					return true
	return false

## 检查是否绝杀 (被将军且无解)
static func is_checkmate(board_logic: BoardLogic, side: Constants.Side) -> bool:
	if not is_in_check(board_logic, side):
		return false
	
	# 如果有任何一步合法走法能解围，则不是绝杀
	return not _has_any_valid_move(board_logic, side)

## 检查是否困毙 (未被将军但无路可走)
static func is_stalemate(board_logic: BoardLogic, side: Constants.Side) -> bool:
	if is_in_check(board_logic, side):
		return false
	
	return not _has_any_valid_move(board_logic, side)

## 检查飞将 (将帅对面)
## 如果将帅在同一列且中间无子，返回 true
static func check_flying_general(board_logic: BoardLogic) -> bool:
	var red_general = _find_general(board_logic, Constants.Side.RED)
	var black_general = _find_general(board_logic, Constants.Side.BLACK)
	
	if red_general == Vector2i(-1, -1) or black_general == Vector2i(-1, -1):
		return false
		
	# 必须在同一列
	if red_general.x != black_general.x:
		return false
		
	# 检查中间是否有棋子
	var col = red_general.x
	var start_y = min(red_general.y, black_general.y) + 1
	var end_y = max(red_general.y, black_general.y)
	
	for y in range(start_y, end_y):
		if board_logic.get_piece_at(Vector2i(col, y)) != null:
			return false # 有阻挡
			
	return true # 无阻挡，飞将

## 辅助：寻找将/帅位置
static func _find_general(board_logic: BoardLogic, side: Constants.Side) -> Vector2i:
	for x in range(Constants.BOARD_COLS):
		for y in range(Constants.BOARD_ROWS):
			var p = board_logic.get_piece_at(Vector2i(x, y))
			if p and p.side == side and p.type == Constants.PieceType.GENERAL:
				return Vector2i(x, y)
	return Vector2i(-1, -1)

## 辅助：检查某方是否有任何合法走法 (Valid Moves)
static func _has_any_valid_move(board_logic: BoardLogic, side: Constants.Side) -> bool:
	# 获取该方所有棋子的所有 legal moves
	var all_pieces_moves = MoveGenerator.get_all_legal_moves(board_logic, side)
	
	for move_info in all_pieces_moves:
		var from_pos = move_info["from"]
		var to_pos = move_info["to"]
		
		# 模拟移动
		var captured = board_logic.move_piece(from_pos, to_pos)
		# move_piece 会切换回合，我们需要切换回来以便检测 side 的状态
		board_logic.switch_turn() 
		
		# 检查是否自杀 (被将军) 或 飞将
		var valid = true
		if is_in_check(board_logic, side):
			valid = false
		elif check_flying_general(board_logic):
			valid = false
			
		# 撤销移动
		board_logic.undo_last_move()
		# undo_last_move 会恢复回合
		
		if valid:
			return true
			
	return false
