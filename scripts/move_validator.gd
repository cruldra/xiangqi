class_name MoveValidator
extends Object

## 棋子走法验证器
##
## 包含各种棋子的特殊走法规则验证逻辑。
## 注意：此验证器主要关注几何规则和路径阻挡，不负责检查“是否被将军”或“目标点是否为己方棋子”。

## 验证将/帅 (General) 走法
## 规则：
## 1. 必须在己方九宫格内移动
## 2. 每次只能水平或垂直移动一格
static func validate_general(from_pos: Vector2i, to_pos: Vector2i, side: Constants.Side) -> bool:
	# 1. 检查目标位置是否在九宫格内
	if not _is_in_palace(to_pos, side):
		return false

	# 2. 检查移动步长 (只能走一格直线)
	var dx = abs(to_pos.x - from_pos.x)
	var dy = abs(to_pos.y - from_pos.y)

	# dx + dy == 1 意味着水平移动一格或垂直移动一格，且不同时移动
	return (dx + dy) == 1

## 验证士/仕 (Advisor) 走法
## 规则：
## 1. 必须在己方九宫格内移动
## 2. 每次只能斜走一格 (dx=1, dy=1)
static func validate_advisor(from_pos: Vector2i, to_pos: Vector2i, side: Constants.Side) -> bool:
	# 1. 检查目标位置是否在九宫格内
	if not _is_in_palace(to_pos, side):
		return false

	# 2. 检查移动步长
	var dx = abs(to_pos.x - from_pos.x)
	var dy = abs(to_pos.y - from_pos.y)

	return dx == 1 and dy == 1

## 验证象/相 (Elephant) 走法
## 规则：
## 1. "田"字形走法 (dx=2, dy=2)
## 2. 不能过河
## 3. "塞象眼"：移动路径中心不能有棋子
static func validate_elephant(from_pos: Vector2i, to_pos: Vector2i, side: Constants.Side, board: Array) -> bool:
	var dx = abs(to_pos.x - from_pos.x)
	var dy = abs(to_pos.y - from_pos.y)

	# 1. 检查步长
	if dx != 2 or dy != 2:
		return false

	# 2. 检查过河
	if side == Constants.Side.RED:
		if to_pos.y < Constants.RIVER_ROW_RED_SIDE: # 红方相不能去 y < 5 的地方 (即不能去黑方区域 0-4)
			return false
	elif side == Constants.Side.BLACK:
		if to_pos.y > Constants.RIVER_ROW_BLACK_SIDE: # 黑方象不能去 y > 4 的地方
			return false

	# 3. 检查塞象眼 (路径中心)
	var eye_pos = (from_pos + to_pos) / 2
	if board[eye_pos.x][eye_pos.y] != null:
		return false

	return true

## 验证马 (Horse) 走法
## 规则：
## 1. "日"字形走法 (dx=1, dy=2 或 dx=2, dy=1)
## 2. "蹩马腿"：移动方向上的紧邻交叉点不能有棋子
static func validate_horse(from_pos: Vector2i, to_pos: Vector2i, board: Array) -> bool:
	var dx: int = to_pos.x - from_pos.x
	var dy: int = to_pos.y - from_pos.y
	var abs_dx = abs(dx)
	var abs_dy = abs(dy)

	# 1. 检查步长
	if not ((abs_dx == 1 and abs_dy == 2) or (abs_dx == 2 and abs_dy == 1)):
		return false

	# 2. 检查蹩马腿
	var leg_pos: Vector2i
	if abs_dx == 2:
		# 横走2格，马腿在横向紧邻处
		leg_pos = from_pos + Vector2i(sign(dx), 0)
	else: # abs_dy == 2
		# 竖走2格，马腿在纵向紧邻处
		leg_pos = from_pos + Vector2i(0, sign(dy))

	if board[leg_pos.x][leg_pos.y] != null:
		return false

	return true

## 验证车 (Chariot) 走法
## 规则：
## 1. 直线移动 (dx=0 或 dy=0)
## 2. 路径上不能有棋子阻挡
static func validate_chariot(from_pos: Vector2i, to_pos: Vector2i, board: Array) -> bool:
	var dx: int = to_pos.x - from_pos.x
	var dy: int = to_pos.y - from_pos.y

	# 1. 检查是否直线
	if dx != 0 and dy != 0:
		return false

	# 2. 检查路径阻挡 (不包含起点和终点)
	return _count_pieces_between(from_pos, to_pos, board) == 0

## 验证炮 (Cannon) 走法
## 规则：
## 1. 直线移动
## 2. 移动(不吃子)：路径上不能有棋子，且目标点为空
## 3. 吃子：路径上必须正好有一个棋子(炮架)，且目标点有棋子(由外部逻辑保证，这里只校验路径)
##
## 注意：此函数需要知道目标点是否有棋子，以便区分移动和吃子逻辑
static func validate_cannon(from_pos: Vector2i, to_pos: Vector2i, board: Array) -> bool:
	var dx: int = to_pos.x - from_pos.x
	var dy: int = to_pos.y - from_pos.y

	# 1. 检查是否直线
	if dx != 0 and dy != 0:
		return false

	var pieces_between: int = _count_pieces_between(from_pos, to_pos, board)
	var target_has_piece = board[to_pos.x][to_pos.y] != null

	if target_has_piece:
		# 吃子模式：中间必须有且仅有1个棋子 (炮架)
		return pieces_between == 1
	else:
		# 移动模式：中间不能有棋子
		return pieces_between == 0

## 验证兵/卒 (Soldier) 走法
## 规则：
## 1. 只能前进，不能后退
## 2. 未过河：只能直走
## 3. 过河后：可直走或横走
## 4. 每次只能走一格
static func validate_soldier(from_pos: Vector2i, to_pos: Vector2i, side: Constants.Side) -> bool:
	var dx: int = to_pos.x - from_pos.x
	var dy: int = to_pos.y - from_pos.y
	var abs_dx = abs(dx)
	var abs_dy = abs(dy)

	# 1. 只能走一格
	if abs_dx + abs_dy != 1:
		return false

	# 2. 检查方向
	if side == Constants.Side.RED:
		# 红方：y必须减小 (向上) 或 横向
		# 如果是后退 (y增加)，则非法
		if dy > 0:
			return false

		# 检查过河前
		# 红方河界是5，y>=5表示未过河 (5,6,7,8,9)
		if from_pos.y >= Constants.RIVER_ROW_RED_SIDE:
			# 未过河，不能横走
			if abs_dx > 0:
				return false

	else: # Black
		# 黑方：y必须增加 (向下) 或 横向
		# 如果是后退 (y减小)，则非法
		if dy < 0:
			return false

		# 检查过河前
		# 黑方河界是4，y<=4表示未过河 (0,1,2,3,4)
		if from_pos.y <= Constants.RIVER_ROW_BLACK_SIDE:
			# 未过河，不能横走
			if abs_dx > 0:
				return false

	return true

## 辅助：计算两点之间的棋子数量 (直线)
static func _count_pieces_between(from: Vector2i, to: Vector2i, board: Array) -> int:
	var count = 0
	var dx = sign(to.x - from.x)
	var dy = sign(to.y - from.y)

	var current = from + Vector2i(dx, dy)
	while current != to:
		if board[current.x][current.y] != null:
			count += 1
		current += Vector2i(dx, dy)

	return count

## 辅助：判断坐标是否在九宫格内
static func _is_in_palace(pos: Vector2i, side: Constants.Side) -> bool:
	if side == Constants.Side.RED:
		return pos.x >= Constants.RED_PALACE_MIN_COL and pos.x <= Constants.RED_PALACE_MAX_COL and \
			   pos.y >= Constants.RED_PALACE_MIN_ROW and pos.y <= Constants.RED_PALACE_MAX_ROW
	elif side == Constants.Side.BLACK:
		return pos.x >= Constants.BLACK_PALACE_MIN_COL and pos.x <= Constants.BLACK_PALACE_MAX_COL and \
			   pos.y >= Constants.BLACK_PALACE_MIN_ROW and pos.y <= Constants.BLACK_PALACE_MAX_ROW
	return false
