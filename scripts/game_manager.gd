extends Node

## 游戏管理器 (Autoload)
##
## 负责协调游戏流程、输入处理和状态管理。
## 连接 BoardLogic (数据) 和 Board (视图)。

var board_logic: BoardLogic

## 当前选中的棋子位置 (-1,-1 表示未选中)
var selected_pos: Vector2i = Vector2i(-1, -1)

##	是否正在播放动画，锁定输入
var is_animating: bool = false

func _ready():
	# 初始化逻辑层
	board_logic = BoardLogic.new()

	# 连接信号
	EventBus.piece_selected.connect(_on_piece_selected)
	EventBus.grid_clicked.connect(_on_grid_clicked)
	EventBus.animation_finished.connect(_on_animation_finished)

	# 可以在这里做一些初始化设置，或者等待 Main 场景调用 start_game

## 启动新游戏
func start_new_game():
	board_logic.setup_initial_position()
	selected_pos = Vector2i(-1, -1)
	is_animating = false
	EventBus.game_started.emit()
	AudioManager.play_move() # Play sound on start
	# 通知视图层刷新 (通常由 Main 场景调用 Board.spawn_pieces)

## 处理棋子被选中事件
func _on_piece_selected(piece_data: PieceData, pos: Vector2i) -> void:
	if is_animating:
		return

	# 1. 如果点击的是当前回合方的棋子 -> 选中它
	if piece_data.side == board_logic.current_turn:
		_select_piece(pos)
	# 2. 如果点击的是对方棋子，且当前已选中了己方棋子 -> 尝试吃子
	elif selected_pos != Vector2i(-1, -1):
		_try_move_to(pos)

## 处理网格点击事件 (空位)
func _on_grid_clicked(pos: Vector2i) -> void:
	if is_animating:
		return

	# 如果已选中棋子 -> 尝试移动
	if selected_pos != Vector2i(-1, -1):
		_try_move_to(pos)

## 动画结束回调
func _on_animation_finished():
	is_animating = false

## 选中棋子并显示走法
func _select_piece(pos: Vector2i):
	selected_pos = pos
	var moves: Array[Vector2i] = MoveGenerator.get_valid_moves(board_logic, pos)
	EventBus.update_highlights.emit(pos, moves)

## 尝试移动到目标位置
func _try_move_to(target_pos: Vector2i):
	# 重新获取当前选中棋子的合法走法 (也可以缓存)
	var valid_moves: Array[Vector2i] = MoveGenerator.get_valid_moves(board_logic, selected_pos)

	if target_pos in valid_moves:
		_execute_move(target_pos)
	else:
		# 如果移动非法
		# 如果点的是空地，取消选中
		if board_logic.get_piece_at(target_pos) == null:
			_deselect_piece()
		# 如果点的是敌人但不能吃，也取消选中? 或者保持选中?
		# 通常保持选中比较好，或者什么都不做。这里选择取消选中以保持反馈清晰。
		# _deselect_piece()
		pass

## 执行移动
func _execute_move(to_pos: Vector2i):
	var from_pos = selected_pos

	# 逻辑层移动
	var captured = board_logic.move_piece(from_pos, to_pos)

	# 播放音效
	if captured:
		AudioManager.play_capture()
	else:
		AudioManager.play_move()

	# 锁定输入，等待动画
	is_animating = true

	# 通知视图层
	EventBus.move_executed.emit(from_pos, to_pos)

	# 清除状态
	_deselect_piece()

	# 通知 UI 更新历史记录
	# 假设 move_history 最后一个元素是我们刚走的
	var last_move = board_logic.move_history.back()
	if last_move:
		EventBus.history_updated.emit(last_move["name"])

	# 通知回合切换
	EventBus.turn_changed.emit(board_logic.current_turn)

	# 检查游戏状态 (将军/绝杀/困毙)
	var opponent = board_logic.current_turn
	if CheckDetector.is_checkmate(board_logic, opponent):
		var winner = Constants.Side.BLACK if opponent == Constants.Side.RED else Constants.Side.RED
		print("Checkmate! Winner: ", winner)
		AudioManager.play_game_over()
		EventBus.game_over.emit(winner)
	elif CheckDetector.is_stalemate(board_logic, opponent):
		var winner = Constants.Side.BLACK if opponent == Constants.Side.RED else Constants.Side.RED
		print("Stalemate! Winner: ", winner) # 象棋规则：困毙判负
		AudioManager.play_game_over()
		EventBus.game_over.emit(winner)
	elif CheckDetector.is_in_check(board_logic, opponent):
		print("Check detected on: ", opponent)
		AudioManager.play_check()
		EventBus.check_detected.emit(opponent)

## 取消选中
func _deselect_piece():
	selected_pos = Vector2i(-1, -1)
	EventBus.clear_highlights.emit()

## 悔棋
func undo_last_move():
	if is_animating:
		return

	if board_logic.undo_last_move():
		EventBus.undo_executed.emit()
		# 刷新棋盘显示 (通知 View 层重绘)
		EventBus.board_refreshed.emit(board_logic)
		# 刷新回合显示
		EventBus.turn_changed.emit(board_logic.current_turn)
		AudioManager.play_move() # Undo sound
