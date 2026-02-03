class_name NotationGenerator
extends Object

## 生成中国象棋标准记谱
## 格式：[棋子名称][路径/方向][目标位置/步数]
## 红方使用中文数字 (一~九)，黑方使用阿拉伯数字 (1~9)

static func get_move_name(board_logic: BoardLogic, from: Vector2i, to: Vector2i) -> String:
	var piece = board_logic.get_piece_at(from)
	if not piece:
		return ""
	
	var side = piece.side
	var type = piece.type
	
	# 1. Determine Piece Name and Ambiguity (Front/Back)
	# 检查同列是否有同类棋子
	var col_pieces = [] # list of y coordinates
	for y in range(Constants.BOARD_ROWS):
		var p = board_logic.get_piece_at(Vector2i(from.x, y))
		if p and p.side == side and p.type == type:
			col_pieces.append(y)
	
	var piece_char = Constants.PIECE_CHARACTERS[side][type]
	var prefix = "" # 前/后/中 or empty
	
	if col_pieces.size() > 1:
		# 处理多子情况
		# 排序：从上到下 (y 递增)
		col_pieces.sort()
		
		var index = col_pieces.find(from.y)
		var count = col_pieces.size()
		
		if count == 2:
			# 两子：前/后
			if side == Constants.Side.RED:
				# 红方：y 小的是前，y 大的是后
				if index == 0: prefix = "前"
				else: prefix = "后"
			else:
				# 黑方：y 大的是前，y 小的是后
				if index == 1: prefix = "前"
				else: prefix = "后"
		elif count == 3:
			# 三子：前/中/后 (主要针对兵/卒)
			# 这里简化处理，通常兵/卒多于2个时不使用前后，而是用列号
			# 但标准记谱中，兵卒如果同列多于2个，也有规则，比较复杂。
			# 考虑到非兵卒很难有3个同列（除非变体），这里针对兵卒做特殊处理或通用处理
			# 兵卒特殊：前兵、中兵、后兵 (Red: index 0->前, 1->中, 2->后)
			if side == Constants.Side.RED:
				if index == 0: prefix = "前"
				elif index == 1: prefix = "中"
				else: prefix = "后"
			else:
				if index == 2: prefix = "前"
				elif index == 1: prefix = "中"
				else: prefix = "后"
		else:
			# >3 个，通常用二兵、三兵等，这里暂不处理极端情况
			pass
			
	# 如果有前缀，棋子名通常省略（如“前炮”），但如果是兵可能需要“前兵”
	# 标准：前炮平五，前兵进一
	# 组合：Prefix + PieceChar
	var name_part = piece_char
	if prefix != "":
		name_part = prefix + piece_char
		
	# 2. Determine Movement Action (Adv/Ret/Flat) and Target
	# 进 (Forward), 退 (Backward), 平 (Horizontal)
	var action = ""
	var target_char = ""
	
	var dy = to.y - from.y # +: Down, -: Up
	var dx = abs(to.x - from.x)
	
	# Determine logical direction based on side
	var is_moving_forward = false
	var is_moving_backward = false
	
	if side == Constants.Side.RED:
		if dy < 0: is_moving_forward = true
		elif dy > 0: is_moving_backward = true
	else: # BLACK
		if dy > 0: is_moving_forward = true
		elif dy < 0: is_moving_backward = true
		
	if from.y == to.y:
		action = "平"
	elif is_moving_forward:
		action = "进"
	elif is_moving_backward:
		action = "退"
		
	# 3. Determine Target Number
	# 红方：列号从右向左 1-9 (x=8 -> 1, x=0 -> 9) => col = 9 - x
	# 黑方：列号从右向左 1-9 (x=0 -> 1, x=8 -> 9) => col = x + 1
	
	var target_val = 0
	
	# For "Flat" (平): Always target column
	if action == "平":
		target_val = _get_column_number(to.x, side)
	else:
		# Vertical moves (进/退)
		# 斜线走子 (马, 相, 士): always target column
		if type in [Constants.PieceType.HORSE, Constants.PieceType.ELEPHANT, Constants.PieceType.ADVISOR]:
			target_val = _get_column_number(to.x, side)
		else:
			# 直线走子 (车, 炮, 兵, 将):
			# 进/退 x 步
			target_val = abs(from.y - to.y)
			
	# Convert number to character
	target_char = _number_to_char(target_val, side)
	
	return name_part + action + target_char

static func _get_column_number(x_idx: int, side: Constants.Side) -> int:
	if side == Constants.Side.RED:
		return 9 - x_idx
	else:
		return x_idx + 1

static func _number_to_char(num: int, side: Constants.Side) -> String:
	if side == Constants.Side.RED:
		const RED_NUMS = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
		if num >= 1 and num <= 9:
			return RED_NUMS[num]
		return str(num) # Fallback
	else:
		return str(num)
