## 全局事件总线单例
##
## 用于在游戏各组件之间进行解耦通信。
## 所有游戏核心事件都通过此单例发射和监听，避免组件间的直接依赖。
##
## 使用方式:
##   发射信号: EventBus.piece_selected.emit(piece_data, grid_pos)
##   监听信号: EventBus.piece_selected.connect(_on_piece_selected)
extends Node

# ============================================================================
# 棋子交互信号
# ============================================================================

## 棋子被选中
## @param piece_data: PieceData - 被选中棋子的数据
## @param grid_pos: Vector2i - 棋子在棋盘上的位置 (列, 行)
signal piece_selected(piece_data: PieceData, grid_pos: Vector2i)

## 请求移动棋子 (由UI层发出，等待逻辑层验证)
## @param from_pos: Vector2i - 起始位置
## @param to_pos: Vector2i - 目标位置
signal move_requested(from_pos: Vector2i, to_pos: Vector2i)

## 走棋执行完成 (逻辑层验证通过后发出)
## @param from_pos: Vector2i - 起始位置
## @param to_pos: Vector2i - 目标位置
signal move_executed(from_pos: Vector2i, to_pos: Vector2i)

# ============================================================================
# 游戏状态信号
# ============================================================================

## 回合切换
## @param new_turn: Constants.Side - 新的当前回合方
signal turn_changed(new_turn: Constants.Side)

## 检测到将军
## @param side: Constants.Side - 被将军的一方
signal check_detected(side: Constants.Side)

## 游戏结束
## @param winner: Constants.Side - 获胜方 (NONE 表示和棋)
signal game_over(winner: Constants.Side)

# ============================================================================
# 扩展信号 (供未来功能使用)
# ============================================================================

## 棋子取消选中
signal piece_deselected()

## 悔棋执行
signal move_undone()

## 新游戏开始
signal game_started()
