extends Node2D

@onready var board: Node2D = $Board

func _ready():
	print("Main Scene Ready")
	
	# 使用 GameManager 启动游戏
	GameManager.start_new_game()

	# 显示棋子
	if board:
		board.spawn_pieces(GameManager.board_logic)
	else:
		push_error("Board node not found in Main!")
