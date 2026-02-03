class_name Piece
extends Area2D

## 棋子组件
##
## 负责显示棋子的视觉状态（背景、汉字、颜色）并处理输入事件。
## 数据由 PieceData 驱动。

# 棋子数据引用
var piece_data: PieceData

# 节点引用
@onready var character_label: Label = $CharacterLabel
@onready var background: Sprite2D = $Background
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready():
	# 连接输入事件信号
	input_event.connect(_on_input_event)

## 初始化棋子
## @param data: PieceData - 棋子数据
func setup(data: PieceData):
	piece_data = data
	update_visual()

## 更新视觉显示
func update_visual() -> void:
	if not piece_data:
		return

	# 更新显示的汉字
	character_label.text = piece_data.character

	# 根据阵营设置颜色
	# 红方使用红色，黑方使用黑色
	if piece_data.side == Constants.Side.RED:
		character_label.add_theme_color_override("font_color", Color("#cc0000"))
	else:
		character_label.add_theme_color_override("font_color", Color("#111111"))

## 处理输入事件 (点击)
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 发射选中信号
			if piece_data:
				EventBus.piece_selected.emit(piece_data, piece_data.board_pos)
				print("Piece selected: ", piece_data.character, " at ", piece_data.board_pos)

## 播放移动动画
## @param target_pos: Vector2 - 目标像素坐标
## @return Tween - 动画对象
func animate_move(target_pos: Vector2) -> Tween:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target_pos, 0.3)
	return tween
