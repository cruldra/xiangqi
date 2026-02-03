extends SceneTree

func _init():
	print("Starting Move Validation Tests...")
	test_cannon_validation()
	test_horse_blocking()
	test_elephant_blocking()
	test_soldier_crossing()
	print("All Tests Completed.")
	quit()

func assert_true(condition: bool, msg: String):
	if not condition:
		print("FAILED: " + msg)
	else:
		print("PASS: " + msg)

func assert_has_move(moves: Array[Vector2i], target: Vector2i, msg: String):
	if target in moves:
		print("PASS: " + msg)
	else:
		print("FAILED: " + msg + " (Target " + str(target) + " not found in moves)")

func assert_no_move(moves: Array[Vector2i], target: Vector2i, msg: String):
	if target not in moves:
		print("PASS: " + msg)
	else:
		print("FAILED: " + msg + " (Target " + str(target) + " found but should be invalid)")

func test_cannon_validation():
	print("\n--- Test Cannon Validation ---")
	var board_logic = BoardLogic.new()
	# Clear board first
	for x in range(Constants.BOARD_COLS):
		for y in range(Constants.BOARD_ROWS):
			board_logic.set_piece_at(Vector2i(x, y), null)
			
	# Setup:
	# Red Cannon at (1, 7)
	# Red Soldier at (1, 4) (Platform)
	# Black Chariot at (1, 0) (Target for capture)
	var cannon_pos = Vector2i(1, 7)
	var mount_pos = Vector2i(1, 4)
	var target_pos = Vector2i(1, 0)
	
	board_logic.set_piece_at(cannon_pos, PieceData.new(Constants.PieceType.CANNON, Constants.Side.RED, cannon_pos))
	board_logic.set_piece_at(mount_pos, PieceData.new(Constants.PieceType.SOLDIER, Constants.Side.RED, mount_pos))
	board_logic.set_piece_at(target_pos, PieceData.new(Constants.PieceType.CHARIOT, Constants.Side.BLACK, target_pos))
	
	var moves = MoveGenerator.get_legal_moves(board_logic, cannon_pos)
	
	# Should be able to capture at (1, 0) - Jump over mount
	assert_has_move(moves, target_pos, "Cannon should capture Black Chariot at (1, 0)")
	
	# Should be able to move to (1, 5), (1, 6) - Between cannon and mount
	assert_has_move(moves, Vector2i(1, 6), "Cannon should move to (1, 6)")
	assert_has_move(moves, Vector2i(1, 5), "Cannon should move to (1, 5)")
	
	# Should NOT move to (1, 4) - Self occupied
	assert_no_move(moves, mount_pos, "Cannon cannot land on own Soldier")
	
	# Should NOT move to (1, 3), (1, 2), (1, 1) - Blocked by mount (no capture target)
	assert_no_move(moves, Vector2i(1, 3), "Cannon cannot move to (1, 3) (Empty after mount)")
	assert_no_move(moves, Vector2i(1, 2), "Cannon cannot move to (1, 2) (Empty after mount)")

func test_horse_blocking():
	print("\n--- Test Horse Blocking (Bie Ma Tui) ---")
	var board_logic = BoardLogic.new()
	# Clear board
	for x in range(Constants.BOARD_COLS):
		for y in range(Constants.BOARD_ROWS):
			board_logic.set_piece_at(Vector2i(x, y), null)
			
	# Setup: Red Horse at (4, 4)
	var horse_pos = Vector2i(4, 4)
	board_logic.set_piece_at(horse_pos, PieceData.new(Constants.PieceType.HORSE, Constants.Side.RED, horse_pos))
	
	# 1. No blocks - should have 8 moves
	var moves = MoveGenerator.get_legal_moves(board_logic, horse_pos)
	assert_true(moves.size() == 8, "Unblocked Horse should have 8 moves")
	
	# 2. Block upward leg (4, 3)
	var block_pos = Vector2i(4, 3)
	board_logic.set_piece_at(block_pos, PieceData.new(Constants.PieceType.SOLDIER, Constants.Side.RED, block_pos))
	
	moves = MoveGenerator.get_legal_moves(board_logic, horse_pos)
	
	# Should NOT reach (3, 2) and (5, 2)
	assert_no_move(moves, Vector2i(3, 2), "Blocked Horse cannot reach (3, 2)")
	assert_no_move(moves, Vector2i(5, 2), "Blocked Horse cannot reach (5, 2)")
	
	# Should reach others, e.g. (6, 5) (Right-Down)
	assert_has_move(moves, Vector2i(6, 5), "Horse should still reach unblocked (6, 5)")

func test_elephant_blocking():
	print("\n--- Test Elephant Blocking (Sai Xiang Yan) ---")
	var board_logic = BoardLogic.new()
	for x in range(Constants.BOARD_COLS):
		for y in range(Constants.BOARD_ROWS):
			board_logic.set_piece_at(Vector2i(x, y), null)
			
	# Red Elephant at (2, 9)
	var ele_pos = Vector2i(2, 9)
	board_logic.set_piece_at(ele_pos, PieceData.new(Constants.PieceType.ELEPHANT, Constants.Side.RED, ele_pos))
	
	# Block eye at (3, 8)
	var eye_pos = Vector2i(3, 8)
	board_logic.set_piece_at(eye_pos, PieceData.new(Constants.PieceType.SOLDIER, Constants.Side.RED, eye_pos))
	
	var moves = MoveGenerator.get_legal_moves(board_logic, ele_pos)
	
	# Should NOT reach (4, 7)
	assert_no_move(moves, Vector2i(4, 7), "Blocked Elephant cannot reach (4, 7)")
	
	# Try another direction: (0, 7) - Eye at (1, 8) is empty
	assert_has_move(moves, Vector2i(0, 7), "Elephant should reach (0, 7)")

func test_soldier_crossing():
	print("\n--- Test Soldier Crossing River ---")
	var board_logic = BoardLogic.new()
	for x in range(Constants.BOARD_COLS):
		for y in range(Constants.BOARD_ROWS):
			board_logic.set_piece_at(Vector2i(x, y), null)
			
	# Red Soldier at (0, 5) - Just crossed river (River is 4-5)
	# Wait, Red starts at bottom. River Red side is 5.
	# If soldier is at (0, 5) it is AT the river bank (on Red side).
	# Moving to (0, 4) crosses the river.
	
	var soldier_pos = Vector2i(0, 5)
	board_logic.set_piece_at(soldier_pos, PieceData.new(Constants.PieceType.SOLDIER, Constants.Side.RED, soldier_pos))
	
	var moves = MoveGenerator.get_legal_moves(board_logic, soldier_pos)
	
	# Can only move forward (0, 4). Cannot move side.
	assert_has_move(moves, Vector2i(0, 4), "Soldier at river bank can move forward")
	assert_no_move(moves, Vector2i(1, 5), "Soldier before river CANNOT move sideways")
	
	# Move Soldier across river to (0, 4)
	board_logic.set_piece_at(soldier_pos, null)
	soldier_pos = Vector2i(0, 4)
	board_logic.set_piece_at(soldier_pos, PieceData.new(Constants.PieceType.SOLDIER, Constants.Side.RED, soldier_pos))
	
	moves = MoveGenerator.get_legal_moves(board_logic, soldier_pos)
	
	# Can move forward (0, 3) AND side (1, 4)
	assert_has_move(moves, Vector2i(0, 3), "Soldier crossed river can move forward")
	assert_has_move(moves, Vector2i(1, 4), "Soldier crossed river can move sideways")
