## 棋盘逻辑类
##
## 负责维护棋盘的逻辑状态，包括棋子的位置、当前回合以及走棋历史。
## 该类不直接参与渲染，仅处理数据运算。
class_name BoardLogic
extends Object

## 棋盘二维数组 [列][行]
var board: Array = []

## 当前行动方
var current_turn: Constants.Side = Constants.Side.RED

## 走棋历史记录 (用于悔棋)
var move_history: Array = []

func _init():
	_setup_board()

## 初始化棋盘数组
##	1 2 3 4 5 6 7 8 9
##1 ┌─┬─┬─┬─┬─┬─┬─┬─┬─┐
##2 ├─┼─┼─┼─┼─┼─┼─┼─┼─┤
##3 ├─┼─┼─┼─┼─┼─┼─┼─┼─┤
##4 ├─┼─┼─┼─┼─┼─┼─┼─┼─┤
##5 ├─┼─┼─┼─┼─┼─┼─┼─┼─┤
##6 ├─┼─┼─┼─┼─┼─┼─┼─┼─┤
##7 ├─┼─┼─┼─┼─┼─┼─┼─┼─┤
##8 ├─┼─┼─┼─┼─┼─┼─┼─┼─┤
##9 ├─┼─┼─┼─┼─┼─┼─┼─┼─┤
##0 └─┴─┴─┴─┴─┴─┴─┴─┴─┘
func _setup_board():
	board.clear()
	for x in range(Constants.BOARD_COLS):
		var column: Array[Variant] = []
		for y in range(Constants.BOARD_ROWS):
			column.append(null) # null 表示空位
		board.append(column)

## 设置初始棋局
func setup_initial_position():
	_setup_board()
	current_turn = Constants.Side.RED
	move_history.clear()

	for piece_info in Constants.INITIAL_LAYOUT:
		var pos = piece_info["pos"]
		var piece: PieceData = PieceData.new(piece_info["type"], piece_info["side"], pos)
		set_piece_at(pos, piece)

## 获取指定位置的棋子
func get_piece_at(pos: Vector2i) -> PieceData:
	if not is_position_valid(pos):
		return null
	return board[pos.x][pos.y]

## 设置指定位置的棋子
func set_piece_at(pos: Vector2i, piece: PieceData):
	if is_position_valid(pos):
		board[pos.x][pos.y] = piece
		if piece:
			piece.board_pos = pos

## 检查坐标是否在棋盘范围内
func is_position_valid(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < Constants.BOARD_COLS and  pos.y >= 0 and pos.y < Constants.BOARD_ROWS

## 移动棋子 (仅数据层面)
## 返回被吃掉的棋子 (如果有)
func move_piece(from: Vector2i, to: Vector2i) -> PieceData:
	var piece: PieceData = get_piece_at(from)
	if not piece:
		return null

	var captured_piece: PieceData = get_piece_at(to)

	# 记录历史 (简单记录，后续可扩展为专门的 Move 对象)
	var move_name = NotationGenerator.get_move_name(self, from, to)

	var move_record: Dictionary[Variant, Variant] = {
		"from": from,
		"to": to,
		"piece": piece.clone(),
		"captured": captured_piece.clone() if captured_piece else null,
		"turn": current_turn,
		"name": move_name
	}
	move_history.append(move_record)

	# 执行移动
	set_piece_at(from, null)
	set_piece_at(to, piece)

	# 切换回合
	switch_turn()

	return captured_piece

## 切换回合
func switch_turn():
	current_turn = Constants.Side.BLACK if current_turn == Constants.Side.RED else Constants.Side.RED

## 撤销上一步
func undo_last_move() -> bool:
	if move_history.is_empty():
		return false

	var last_move = move_history.pop_back()

	# 恢复位置
	var piece: PieceData = get_piece_at(last_move["to"])
	set_piece_at(last_move["from"], piece)
	set_piece_at(last_move["to"], last_move["captured"])

	# 恢复回合
	current_turn = last_move["turn"]

	return true
