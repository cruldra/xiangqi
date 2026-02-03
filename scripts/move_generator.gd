class_name MoveGenerator
extends Object

## 走法生成器
##
## 负责生成指定棋子的所有合法走法。
## 利用 MoveValidator 进行规则验证，并结合 BoardLogic 获取棋盘状态。

## 获取指定位置棋子的所有"有效"走法 (包含被将军检测)
static func get_valid_moves(board_logic: BoardLogic, pos: Vector2i) -> Array[Vector2i]:
	var legal_moves: Array[Vector2i] = get_legal_moves(board_logic, pos)
	var valid_moves: Array[Vector2i] = []
	var piece: PieceData = board_logic.get_piece_at(pos)
	if not piece: return []
	var side: Constants.Side = piece.side

	for to_pos in legal_moves:
		# 模拟
		board_logic.move_piece(pos, to_pos)
		board_logic.switch_turn() # 换回己方视角

		var is_safe: bool = true
		if CheckDetector.is_in_check(board_logic, side):
			is_safe = false
		elif CheckDetector.check_flying_general(board_logic):
			is_safe = false

		board_logic.undo_last_move() # 恢复

		if is_safe:
			valid_moves.append(to_pos)

	return valid_moves

## 获取指定位置棋子的所有合法走法 (不包含被将军检测)
static func get_legal_moves(board_logic: BoardLogic, pos: Vector2i) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []

	if not board_logic.is_position_valid(pos):
		return moves

	var piece = board_logic.get_piece_at(pos)
	if not piece:
		return moves

	var side = piece.side
	var type = piece.type
	var board = board_logic.board

	# 根据棋子类型生成潜在目标位置
	var candidates: Array[Vector2i] = []

	match type:
		Constants.PieceType.GENERAL:
			candidates = _get_offsets_moves(pos, [
				Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)
			])
		Constants.PieceType.ADVISOR:
			candidates = _get_offsets_moves(pos, [
				Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
			])
		Constants.PieceType.ELEPHANT:
			candidates = _get_offsets_moves(pos, [
				Vector2i(2, 2), Vector2i(2, -2), Vector2i(-2, 2), Vector2i(-2, -2)
			])
		Constants.PieceType.HORSE:
			candidates = _get_offsets_moves(pos, [
				Vector2i(1, 2), Vector2i(1, -2), Vector2i(-1, 2), Vector2i(-1, -2),
				Vector2i(2, 1), Vector2i(2, -1), Vector2i(-2, 1), Vector2i(-2, -1)
			])
		Constants.PieceType.SOLDIER:
			candidates = _get_offsets_moves(pos, [
				Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)
			])
		Constants.PieceType.CHARIOT, Constants.PieceType.CANNON:
			candidates = _get_linear_moves(pos)

	# 过滤非法走法
	for target in candidates:
		# 1. 检查边界 (已在 candidate生成中部分涵盖，但再次检查无妨)
		if not board_logic.is_position_valid(target):
			continue

		# 2. 检查是否包含己方棋子 (防止自吃)
		var target_piece = board_logic.get_piece_at(target)
		if target_piece and target_piece.side == side:
			continue

		# 3. 使用 MoveValidator 验证具体规则
		var is_valid = false
		match type:
			Constants.PieceType.GENERAL:
				is_valid = MoveValidator.validate_general(pos, target, side)
			Constants.PieceType.ADVISOR:
				is_valid = MoveValidator.validate_advisor(pos, target, side)
			Constants.PieceType.ELEPHANT:
				is_valid = MoveValidator.validate_elephant(pos, target, side, board)
			Constants.PieceType.HORSE:
				is_valid = MoveValidator.validate_horse(pos, target, board)
			Constants.PieceType.SOLDIER:
				is_valid = MoveValidator.validate_soldier(pos, target, side)
			Constants.PieceType.CHARIOT:
				is_valid = MoveValidator.validate_chariot(pos, target, board)
			Constants.PieceType.CANNON:
				is_valid = MoveValidator.validate_cannon(pos, target, board)

		if is_valid:
			moves.append(target)

	return moves

## 获取某一方所有棋子的所有合法走法
static func get_all_legal_moves(board_logic: BoardLogic, side: Constants.Side) -> Array[Dictionary]:
	var all_moves: Array[Dictionary] = [] # Array of {from: Vector2i, to: Vector2i}

	for x in range(Constants.BOARD_COLS):
		for y in range(Constants.BOARD_ROWS):
			var pos: Vector2i = Vector2i(x, y)
			var piece: PieceData = board_logic.get_piece_at(pos)
			if piece and piece.side == side:
				var moves: Array[Vector2i] = get_legal_moves(board_logic, pos)
				for to in moves:
					all_moves.append({"from": pos, "to": to})

	return all_moves

## 辅助：根据偏移量生成潜在位置
static func _get_offsets_moves(pos: Vector2i, offsets: Array[Vector2i]) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for offset in offsets:
		candidates.append(pos + offset)
	return candidates

## 辅助：生成直线上的所有潜在位置 (十字)
static func _get_linear_moves(pos: Vector2i) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []

	# 横向
	for x in range(Constants.BOARD_COLS):
		if x != pos.x:
			candidates.append(Vector2i(x, pos.y))

	# 纵向
	for y in range(Constants.BOARD_ROWS):
		if y != pos.y:
			candidates.append(Vector2i(pos.x, y))

	return candidates
