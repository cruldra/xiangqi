## 棋子数据资源
##
## 用于存储单个棋子的属性数据，包括类型、阵营以及显示的汉字。
## 该类继承自 Resource，便于在编辑器中查看和序列化存储。
class_name PieceData
extends Resource

## 棋子类型 (见 Constants.PieceType)
@export var type: Constants.PieceType = Constants.PieceType.NONE

## 所属阵营 (见 Constants.Side)
@export var side: Constants.Side = Constants.Side.NONE

## 棋子显示的汉字
@export var character: String = ""

## 棋子在棋盘上的逻辑位置 (列, 行)
@export var board_pos: Vector2i = Vector2i(-1, -1)

## 初始化方法
func _init(_type: Constants.PieceType = Constants.PieceType.NONE,  _side: Constants.Side = Constants.Side.NONE,  _pos: Vector2i = Vector2i(-1, -1)):
	self.type = _type
	self.side = _side
	self.board_pos = _pos

	# 根据阵营和类型自动获取对应的汉字
	if type != Constants.PieceType.NONE and side != Constants.Side.NONE:
		self.character = Constants.PIECE_CHARACTERS[side][type]

## 克隆当前数据对象 (用于悔棋或模拟走位)
func clone() -> PieceData:
	var new_data: PieceData = PieceData.new(type, side, board_pos)
	new_data.character = self.character
	return new_data

## 辅助方法：判断是否为空
func is_empty() -> bool:
	return type == Constants.PieceType.NONE
