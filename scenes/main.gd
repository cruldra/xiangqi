extends Node2D

@onready var board: Node2D = $Board

var board_logic: BoardLogic

func _ready():
	print("Main Scene Ready")
	# 初始化逻辑
	board_logic = BoardLogic.new()
	board_logic.setup_initial_position()

	# 显示棋子
	if board:
		board.spawn_pieces(board_logic)
	else:
		push_error("Board node not found in Main!")
