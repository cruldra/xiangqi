class_name Evaluator
extends Object

## 局势评估器
##
## 负责对当前棋盘状态进行评分。
## 正分代表红方优势，负分代表黑方优势。

# 基础子力价值 (大致参考常见象棋AI权重)
const PIECE_VALUES: Dictionary[Variant, Variant] = {
	Constants.PieceType.GENERAL: 10000,
	Constants.PieceType.CHARIOT: 900,
	Constants.PieceType.CANNON: 450,
	Constants.PieceType.HORSE: 400,
	Constants.PieceType.ELEPHANT: 20,
	Constants.PieceType.ADVISOR: 20,
	Constants.PieceType.SOLDIER: 10,
	Constants.PieceType.NONE: 0
}

# 简单的位置附加分 (简化版，仅区分过河兵)
const SOLDIER_BONUS = 20 # 过河兵加分

## 评估当前局面分数
## @param board_logic: BoardLogic
## @return int: 分数 (Red - Black)
static func evaluate(board_logic: BoardLogic) -> int:
	var score = 0

	for col in range(Constants.BOARD_COLS):
		for row in range(Constants.BOARD_ROWS):
			var piece = board_logic.get_piece_at(Vector2i(col, row))
			if piece:
				var value = PIECE_VALUES.get(piece.type, 0)

				# 特殊位置加分
				if piece.type == Constants.PieceType.SOLDIER:
					value += _get_soldier_bonus(piece, row)

				if piece.side == Constants.Side.RED:
					score += value
				else:
					score -= value

	return score

## 计算兵的附加分
static func _get_soldier_bonus(piece: PieceData, row: int) -> int:
	if piece.side == Constants.Side.RED:
		if row <= Constants.RIVER_ROW_BLACK_SIDE: # 已过河 (行数变小)
			return SOLDIER_BONUS
	else:
		if row >= Constants.RIVER_ROW_RED_SIDE: # 已过河 (行数变大)
			return SOLDIER_BONUS
	return 0
