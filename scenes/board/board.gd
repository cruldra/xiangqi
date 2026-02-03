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

## 高亮状态
var selected_pos: Vector2i = Vector2i(-1, -1)
var legal_moves: Array[Vector2i] = []
## 最近一次移动的起始位置
var last_move_from: Vector2i = Vector2i(-1, -1)
## 最近一次移动的目标位置
var last_move_to: Vector2i = Vector2i(-1, -1)

func _ready():
	# 连接 EventBus 信号
	EventBus.update_highlights.connect(_on_update_highlights)
	EventBus.clear_highlights.connect(_on_clear_highlights)
	EventBus.move_executed.connect(_on_move_executed)
	EventBus.board_refreshed.connect(_on_board_refreshed)
	EventBus.game_started.connect(_on_game_started)

func _on_game_started():
	spawn_pieces(GameManager.board_logic)

func _on_board_refreshed(logic):
	spawn_pieces(logic)
	queue_redraw()

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var local_pos: Vector2 = get_local_mouse_position()
			var grid_pos: Vector2i = local_to_map(local_pos)

			# 简单的边界检查 (0..8, 0..9)
			if grid_pos.x >= 0 and grid_pos.x < Constants.BOARD_COLS and \
			   grid_pos.y >= 0 and grid_pos.y < Constants.BOARD_ROWS:

				# 检查点击是否在有效范围内 (比如距离交叉点不要太远)
				# 这里简化处理：只要是在格子范围内就算点击该交叉点
				EventBus.grid_clicked.emit(grid_pos)

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

	# 绘制最近一次移动的高亮
	_draw_last_move_markers()

	# 绘制高亮和提示
	_draw_highlights()
	_draw_legal_moves()

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

## 绘制最近一次移动的起止位置标记
func _draw_last_move_markers():
	if last_move_from != Vector2i(-1, -1):
		_draw_rect_marker(last_move_from, Color(0, 0, 1, 0.4)) # 蓝色标记
	if last_move_to != Vector2i(-1, -1):
		_draw_rect_marker(last_move_to, Color(0, 0, 1, 0.4))

## 绘制矩形标记 (用于高亮或上一步)
func _draw_rect_marker(pos: Vector2i, color: Color):
	var center: Vector2 = map_to_local(pos)
	var size: float = cell_size * 0.9
	var rect: Rect2 = Rect2(center - Vector2(size/2, size/2), Vector2(size, size))
	draw_rect(rect, color, false, 4.0)

## 将棋盘逻辑坐标 (Grid Position) 转换为本地像素坐标 (Local Pixel Position)
##
## 该函数用于确定棋子或 UI 元素在屏幕上的实际绘制位置。
##
## **为什么需要这个函数？**
## 1. **逻辑与表现分离 (Separation of Concerns)**:
##    游戏核心逻辑 (BoardLogic) 仅关心离散的网格坐标 (0..8, 0..9)，不关心像素。
##    视觉层 (Board) 负责将这些逻辑坐标渲染到屏幕上。
## 2. **适应性 (Adaptability)**:
##    如果将来需要缩放棋盘 (修改 cell_size) 或移动棋盘位置 (修改 margin)，
##    只需调整此函数的参数，所有棋子和标记的位置会自动更新，无需修改逻辑代码。
## 3. **统一转换 (Single Source of Truth)**:
##    所有涉及坐标转换的地方 (绘制棋子、高亮、点击检测) 都调用此函数，保证位置一致。
##
## 计算公式:
##   PixelX = Margin + GridX * CellSize
##   PixelY = Margin + GridY * CellSize
##
## @param grid_pos: Vector2i - 棋盘网格坐标，范围通常是 (0,0) 到 (8,9)
##   - x: 列索引 (0-8)
##   - y: 行索引 (0-9)
## @return Vector2 - 该网格交叉点相对于 Board 节点的本地像素坐标
func map_to_local(grid_pos: Vector2i) -> Vector2:
	return Vector2(margin + grid_pos.x * cell_size, margin + grid_pos.y * cell_size)

## 根据逻辑状态生成棋子
func spawn_pieces(board_logic: BoardLogic) -> void:
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

## 将本地像素坐标转换为棋盘逻辑坐标
func local_to_map(local_pos: Vector2) -> Vector2i:
	var x = round((local_pos.x - margin) / cell_size)
	var y = round((local_pos.y - margin) / cell_size)
	return Vector2i(int(x), int(y))

## 绘制选中高亮框
func _draw_highlights():
	if selected_pos != Vector2i(-1, -1):
		var center: Vector2 = map_to_local(selected_pos)
		var size: float = cell_size * 0.9 # 稍微比格子小一点
		var rect: Rect2 = Rect2(center - Vector2(size/2, size/2), Vector2(size, size))
		draw_rect(rect, Color(0, 1, 0, 0.4), false, 4.0) # 绿色空心框

## 绘制合法走法提示点
func _draw_legal_moves():
	for pos in legal_moves:
		var center: Vector2 = map_to_local(pos)
		draw_circle(center, 8.0, Color(0, 0.8, 0, 0.6)) # 绿色半透明圆点

## 信号处理：更新高亮
func _on_update_highlights(pos: Vector2i, moves: Array[Vector2i]):
	selected_pos = pos
	legal_moves = moves
	queue_redraw()

## 信号处理：清除高亮
func _on_clear_highlights():
	selected_pos = Vector2i(-1, -1)
	legal_moves = []
	queue_redraw()

## 信号处理：执行移动动画
func _on_move_executed(from_pos: Vector2i, to_pos: Vector2i):
	# 更新上次移动高亮
	last_move_from = from_pos
	last_move_to = to_pos
	queue_redraw()

	var moving_piece_node: Node2D = null
	var target_piece_node: Node2D = null

	# 查找对应的棋子节点
	# 注意：此时 PieceData 可能已经更新，但 Visual Node 的 position 还是旧的
	var from_pixel: Vector2 = map_to_local(from_pos)
	var to_pixel: Vector2 = map_to_local(to_pos)

	for child in pieces_container.get_children():
		if child is Piece:
			# 使用距离判断，允许一点点误差
			if child.position.distance_to(from_pixel) < 1.0:
				moving_piece_node = child
			elif child.position.distance_to(to_pixel) < 1.0:
				target_piece_node = child

	# 动画处理
	var main_tween: Tween = null

	# 移动动画
	if moving_piece_node:
		# Piece.animate_move 现在返回 Tween
		main_tween = moving_piece_node.animate_move(to_pixel)
	else:
		push_warning("Visual piece not found for move: " + str(from_pos) + " -> " + str(to_pos))

	# 吃子动画 (渐隐)
	if target_piece_node:
		# 确保层级在移动棋子之下 (可选)
		# target_piece_node.z_index = -1

		var capture_tween = create_tween()
		capture_tween.tween_property(target_piece_node, "modulate:a", 0.0, 0.2)
		capture_tween.tween_callback(target_piece_node.queue_free)

	# 等待主移动动画结束
	if main_tween:
		await main_tween.finished

	# 发送动画结束信号 (解锁输入)
	EventBus.animation_finished.emit()
