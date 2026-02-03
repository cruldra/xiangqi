# res://tests/test_calculator.gd
extends GutTest

# 测试前准备 (比如实例化要测试的类)
var validator

func before_each():
	# 假设你有一个 MoveValidator 类
	validator = MoveValidator.new()

# 测试后清理
func after_each():
	validator.free()

# --- 测试用例 ---

func test_addition():
	# 简单的断言
	assert_eq(1 + 1, 2, "数学应该是对的")

func test_chess_move_valid():
	# 结合你的象棋项目
	var from = Vector2i(0, 0)
	var to = Vector2i(0, 1)
	# 假设 validate_general 返回 true
	var result = validator.validate_general(from, to, Constants.Side.BLACK)

	assert_true(result, "黑将应该能向下移动一格")

func test_chess_move_invalid():
	# 测试非法移动
	var from = Vector2i(0, 0)
	var to = Vector2i(0, 5) # 飞太远了
	var result = validator.validate_general(from, to, Constants.Side.BLACK)

	assert_false(result, "黑将不能一次走5格")
