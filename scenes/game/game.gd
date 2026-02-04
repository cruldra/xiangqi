extends Node2D
## 游戏场景
##
## 包含棋盘和游戏UI的主游戏场景。
## 从主菜单进入，支持返回主菜单功能。

@onready var board: Node2D = $Board

func _ready():
	print("Game Scene Ready")
	
	# 启动新游戏
	GameManager.start_new_game()
	
	# 显示棋子
	if board:
		board.spawn_pieces(GameManager.board_logic)
	else:
		push_error("Board node not found in Game Scene!")

## 处理键盘输入 (ESC返回菜单等)
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		# 显示确认对话框或直接返回
		_show_exit_confirmation()

func _show_exit_confirmation():
	# 发出暂停信号，让GameUI显示确认弹窗
	EventBus.pause_requested.emit()
