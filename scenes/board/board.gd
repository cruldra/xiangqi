## 棋盘可视化组件
##
## 负责绘制棋盘的网格、九宫格、河界以及星位标记。
## 采用 _draw() 函数进行自绘，确保线条清晰且可自适应缩放。
@tool
extends Node2D

## 棋子场景预加载
const PIECE_SCENE: PackedScene = preload("res://scenes/pieces/piece.tscn")

## 棋盘格大小 (像素)
@export var cell_size: float = 80.0:
	set(v):
		cell_size= v
		queue_redraw()

## 棋盘外边距 (像素)
@export var margin: float = 60.0:
	set(v):
		margin = v
		queue_redraw()

## 线条颜色
@export var line_color: Color = Color("#4a3728"):
	set(value):
		line_color = value
		queue_redraw()

## 线条宽度
@export var line_width: float = 2.0:
	set(value):
		line_width = value
		queue_redraw()

## 背景颜色 (模拟木纹深度)
@export var background_color: Color = Color("#dcb35c"):
	set(value):
		background_color = value
		queue_redraw()

## 容器节点引用
@onready var pieces_container: Node2D = $Pieces
@onready var move_indicators_container: Node2D = $MoveIndicators

func _draw():
	# 绘制背景逻辑：先画一个填充矩形作为棋盘底色
	var total_width: float = cell_size * (Constants.BOARD_COLS - 1) + margin * 2
	var total_height: float = cell_size * (Constants.BOARD_ROWS - 1) + margin * 2
	draw_rect(Rect2(0, 0, total_width, total_height), background_color)

	# 绘制网格线逻辑：
	# 1. 先画横线 (10条)
	for i in range(Constants.BOARD_ROWS):
		# 计算当前横线的 y 坐标（从上到下第 i 行）
		var y = margin + i * cell_size
		# 定义横线的起点（左侧边距处）和终点（右侧边距处）
		var start: Vector2 = Vector2(margin, y)
		var end: Vector2 = Vector2(margin + (Constants.BOARD_COLS - 1) * cell_size, y)
		# 绘制横线
		draw_line(start, end, line_color, line_width)

	# 2. 画竖线 (9列)
	# 竖线在河界处是断开的，所以分左右两半画 (或者分上下两半)
	for i in range(Constants.BOARD_COLS):
		var x = margin + i * cell_size

		# 第一列和最后一列是连通的
		if i == 0 or i == Constants.BOARD_COLS - 1:
			var start: Vector2 = Vector2(x, margin)
			var end: Vector2 = Vector2(x, margin + (Constants.BOARD_ROWS - 1) * cell_size)
			draw_line(start, end, line_color, line_width)
		else:
			# 中间列在河界处断开：
			# 绘制上方区域的竖线 (行0到行4)
			draw_line(Vector2(x, margin), Vector2(x, margin + 4 * cell_size), line_color, line_width)
			# 绘制下方区域的竖线 (行5到行9)
			draw_line(Vector2(x, margin + 5 * cell_size), Vector2(x, margin + 9 * cell_size), line_color, line_width)

	# 绘制九宫格斜线逻辑：
	# 在双方底部的 3x3 区域绘制交叉线
	_draw_palace(Vector2i(3, 0)) # 黑方九宫
	_draw_palace(Vector2i(3, 7)) # 红方九宫

	# 绘制星位标记逻辑：
	# 炮位和部分兵位有特殊的“L”型标记
	_draw_star_markers()

## 绘制九宫格交叉线
## palace_top_left: 九宫格左上角的棋盘坐标 (x, y)
func _draw_palace(palace_pos: Vector2i):
	var start_x: float = margin + palace_pos.x * cell_size
	var start_y: float = margin + palace_pos.y * cell_size

	# 九宫格是一个 2x2 格子 (3x3 交叉点) 区域
	var end_x: float = start_x + 2 * cell_size
	var end_y: float = start_y + 2 * cell_size

	# 绘制交叉的两条对角线
	draw_line(Vector2(start_x, start_y), Vector2(end_x, end_y), line_color, line_width)
	draw_line(Vector2(end_x, start_y), Vector2(start_x, end_y), line_color, line_width)

## 绘制星位标记 (炮位和兵位)
func _draw_star_markers():
	# 定义所有星位点坐标
	var star_points: Array[Variant] = [
		Vector2i(1, 2), Vector2i(7, 2), # 黑方炮位
		Vector2i(0, 3), Vector2i(2, 3), Vector2i(4, 3), Vector2i(6, 3), Vector2i(8, 3), # 黑方兵位
		Vector2i(1, 7), Vector2i(7, 7), # 红方炮位
		Vector2i(0, 6), Vector2i(2, 6), Vector2i(4, 6), Vector2i(6, 6), Vector2i(8, 6), # 红方兵位
	]

	for p in star_points:
		_draw_marker(p)

## 在指定交叉点绘制“L”型直角标记
func _draw_marker(grid_pos: Vector2i):
	var center: Vector2 = Vector2(margin + grid_pos.x * cell_size, margin + grid_pos.y * cell_size)
	var gap: float = 4.0   # 标记与交叉点的间隙
	var length: float = 15.0 # 标记臂的长度

	# 每个标记由4个直角组成，分别位于四个象限
	# 左上
	if grid_pos.x > 0:
		draw_line(center + Vector2(-gap, -gap), center + Vector2(-gap - length, -gap), line_color, line_width)
		draw_line(center + Vector2(-gap, -gap), center + Vector2(-gap, -gap - length), line_color, line_width)
	# 右上
	if grid_pos.x < Constants.BOARD_COLS - 1:
		draw_line(center + Vector2(gap, -gap), center + Vector2(gap + length, -gap), line_color, line_width)
		draw_line(center + Vector2(gap, -gap), center + Vector2(gap, -gap - length), line_color, line_width)
	# 左下
	if grid_pos.x > 0:
		draw_line(center + Vector2(-gap, gap), center + Vector2(-gap - length, gap), line_color, line_width)
		draw_line(center + Vector2(-gap, gap), center + Vector2(-gap, gap + length), line_color, line_width)
	# 右下
	if grid_pos.x < Constants.BOARD_COLS - 1:
		draw_line(center + Vector2(gap, gap), center + Vector2(gap + length, gap), line_color, line_width)
		draw_line(center + Vector2(gap, gap), center + Vector2(gap, gap + length), line_color, line_width)

## 将棋盘逻辑坐标转换为本地像素坐标
func map_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(margin + grid_pos.x * cell_size, margin + grid_pos.y * cell_size)

## 根据逻辑状态生成棋子
func spawn_pieces(board_logic: BoardLogic):
	# 清除现有棋子
	if not pieces_container:
		push_error("Pieces container not found!")
		return

	for child in pieces_container.get_children():
		child.queue_free()

	# 遍历棋盘生成新棋子
	for col in range(Constants.BOARD_COLS):
		for row in range(Constants.BOARD_ROWS):
			var pos: Vector2i = Vector2i(col, row)
			var piece_data: PieceData = board_logic.get_piece_at(pos)

			if piece_data:
				var piece_instance: Node = PIECE_SCENE.instantiate()
				pieces_container.add_child(piece_instance)

				# 初始化棋子数据和位置
				piece_instance.setup(piece_data)
				piece_instance.position = map_to_local(pos)
