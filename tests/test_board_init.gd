extends SceneTree

func _init():
	print("开始验证 BoardLogic 初始化逻辑...")
	
	var board_logic = BoardLogic.new()
	board_logic.setup_initial_position()
	
	var errors = 0
	
	# 测试用例定义
	var test_cases = [
		{"pos": Vector2i(0, 0), "type": Constants.PieceType.CHARIOT, "side": Constants.Side.BLACK, "char": "車"},
		{"pos": Vector2i(4, 0), "type": Constants.PieceType.GENERAL, "side": Constants.Side.BLACK, "char": "將"},
		{"pos": Vector2i(4, 9), "type": Constants.PieceType.GENERAL, "side": Constants.Side.RED, "char": "帥"},
		{"pos": Vector2i(0, 9), "type": Constants.PieceType.CHARIOT, "side": Constants.Side.RED, "char": "車"},
		{"pos": Vector2i(4, 4), "type": Constants.PieceType.NONE, "side": Constants.Side.NONE, "char": "null"}
	]
	
	for case in test_cases:
		var piece = board_logic.get_piece_at(case["pos"])
		
		if case["type"] == Constants.PieceType.NONE:
			if piece != null:
				print("错误: 位置 ", case["pos"], " 应该为空，但发现了 ", piece.character)
				errors += 1
			else:
				print("通过: 位置 ", case["pos"], " 为空")
		else:
			if piece == null:
				print("错误: 位置 ", case["pos"], " 应该是 ", case["char"], " 但为空")
				errors += 1
			elif piece.type != case["type"] or piece.side != case["side"]:
				print("错误: 位置 ", case["pos"], " 应该是 ", case["char"], " 实际是 ", piece.character)
				errors += 1
			else:
				print("通过: 位置 ", case["pos"], " 正确放置了 ", piece.character)
				
	if errors == 0:
		print("SUCCESS: 所有初始化测试通过！")
	else:
		print("FAILURE: 发现 ", errors, " 个错误！")
		
	quit()
