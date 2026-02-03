## 中国象棋游戏常量定义
##
## 本文件定义了游戏的全局常量、枚举、棋盘边界以及初始布局配置。
## 采用 Vector2i(x, y) 坐标系，其中 x 对应列 (0-8)，y 对应行 (0-9)。
class_name Constants
extends Node

## 棋盘规格：10行 9列
const BOARD_ROWS: int = 10
const BOARD_COLS: int = 9

## 阵营枚举
enum Side {
	NONE,   # 无/空
	RED,    # 红方 (通常在下方)
	BLACK   # 黑方 (通常在上方)
}

## 棋子类型枚举
enum PieceType {
	NONE,       # 空
	GENERAL,    # 帥/將 (王)
	ADVISOR,    # 仕/士 (卫/助理)
	ELEPHANT,   # 相/象 (相)
	HORSE,      # 馬 (马)
	CHARIOT,    # 車 (车)
	CANNON,     # 炮/砲 (炮)
	SOLDIER     # 兵/卒 (兵)
}

## 黑方九宫格边界 (行 0-2, 列 3-5)
const BLACK_PALACE_MIN_ROW = 0
const BLACK_PALACE_MAX_ROW = 2
const BLACK_PALACE_MIN_COL = 3
const BLACK_PALACE_MAX_COL = 5

## 红方九宫格边界 (行 7-9, 列 3-5)
const RED_PALACE_MIN_ROW = 7
const RED_PALACE_MAX_ROW = 9
const RED_PALACE_MIN_COL = 3
const RED_PALACE_MAX_COL = 5

## 河界定义
## 坐标系统中，行 4 和行 5 之间是楚河汉界
const RIVER_ROW_BLACK_SIDE = 4  # 黑方河界行 (跨过后进入红方领土)
const RIVER_ROW_RED_SIDE = 5    # 红方河界行 (跨过后进入黑方领土)

## 棋子字符映射 (采用繁体中文，符合传统象棋习惯)
const PIECE_CHARACTERS = {
	Side.RED: {
		PieceType.GENERAL: "帥",
		PieceType.ADVISOR: "仕",
		PieceType.ELEPHANT: "相",
		PieceType.HORSE: "馬",
		PieceType.CHARIOT: "車",
		PieceType.CANNON: "炮",
		PieceType.SOLDIER: "兵"
	},
	Side.BLACK: {
		PieceType.GENERAL: "將",
		PieceType.ADVISOR: "士",
		PieceType.ELEPHANT: "象",
		PieceType.HORSE: "馬",
		PieceType.CHARIOT: "車",
		PieceType.CANNON: "砲",
		PieceType.SOLDIER: "卒"
	}
}

## 游戏初始布局配置
## 使用字典数组存储，包含位置(Vector2i)、阵营和类型
const INITIAL_LAYOUT: Array[Variant] = [
	# --- 黑方 (顶部) ---
	{"pos": Vector2i(0, 0), "side": Side.BLACK, "type": PieceType.CHARIOT}, # 车
	{"pos": Vector2i(1, 0), "side": Side.BLACK, "type": PieceType.HORSE},   # 马
	{"pos": Vector2i(2, 0), "side": Side.BLACK, "type": PieceType.ELEPHANT},# 象
	{"pos": Vector2i(3, 0), "side": Side.BLACK, "type": PieceType.ADVISOR}, # 士
	{"pos": Vector2i(4, 0), "side": Side.BLACK, "type": PieceType.GENERAL}, # 将
	{"pos": Vector2i(5, 0), "side": Side.BLACK, "type": PieceType.ADVISOR}, # 士
	{"pos": Vector2i(6, 0), "side": Side.BLACK, "type": PieceType.ELEPHANT},# 象
	{"pos": Vector2i(7, 0), "side": Side.BLACK, "type": PieceType.HORSE},   # 马
	{"pos": Vector2i(8, 0), "side": Side.BLACK, "type": PieceType.CHARIOT}, # 车

	{"pos": Vector2i(1, 2), "side": Side.BLACK, "type": PieceType.CANNON},  # 砲
	{"pos": Vector2i(7, 2), "side": Side.BLACK, "type": PieceType.CANNON},  # 砲

	{"pos": Vector2i(0, 3), "side": Side.BLACK, "type": PieceType.SOLDIER}, # 卒
	{"pos": Vector2i(2, 3), "side": Side.BLACK, "type": PieceType.SOLDIER}, # 卒
	{"pos": Vector2i(4, 3), "side": Side.BLACK, "type": PieceType.SOLDIER}, # 卒
	{"pos": Vector2i(6, 3), "side": Side.BLACK, "type": PieceType.SOLDIER}, # 卒
	{"pos": Vector2i(8, 3), "side": Side.BLACK, "type": PieceType.SOLDIER}, # 卒

	# --- 红方 (底部) ---
	{"pos": Vector2i(0, 9), "side": Side.RED, "type": PieceType.CHARIOT},   # 車
	{"pos": Vector2i(1, 9), "side": Side.RED, "type": PieceType.HORSE},     # 馬
	{"pos": Vector2i(2, 9), "side": Side.RED, "type": PieceType.ELEPHANT},  # 相
	{"pos": Vector2i(3, 9), "side": Side.RED, "type": PieceType.ADVISOR},   # 仕
	{"pos": Vector2i(4, 9), "side": Side.RED, "type": PieceType.GENERAL},   # 帥
	{"pos": Vector2i(5, 9), "side": Side.RED, "type": PieceType.ADVISOR},   # 仕
	{"pos": Vector2i(6, 9), "side": Side.RED, "type": PieceType.ELEPHANT},  # 相
	{"pos": Vector2i(7, 9), "side": Side.RED, "type": PieceType.HORSE},     # 馬
	{"pos": Vector2i(8, 9), "side": Side.RED, "type": PieceType.CHARIOT},   # 車

	{"pos": Vector2i(1, 7), "side": Side.RED, "type": PieceType.CANNON},    # 炮
	{"pos": Vector2i(7, 7), "side": Side.RED, "type": PieceType.CANNON},    # 炮

	{"pos": Vector2i(0, 6), "side": Side.RED, "type": PieceType.SOLDIER},   # 兵
	{"pos": Vector2i(2, 6), "side": Side.RED, "type": PieceType.SOLDIER},   # 兵
	{"pos": Vector2i(4, 6), "side": Side.RED, "type": PieceType.SOLDIER},   # 兵
	{"pos": Vector2i(6, 6), "side": Side.RED, "type": PieceType.SOLDIER},   # 兵
	{"pos": Vector2i(8, 6), "side": Side.RED, "type": PieceType.SOLDIER},   # 兵
]
