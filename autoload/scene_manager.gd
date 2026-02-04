## 场景管理器 (Autoload)
##
## 负责场景切换和过渡动画效果。
## 提供淡入淡出等平滑过渡效果，使游戏更具专业感。
extends Node

## 场景路径常量
const MAIN_MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"

## 过渡动画持续时间
const FADE_DURATION := 0.5

## 过渡遮罩层
var _transition_layer: CanvasLayer
var _transition_rect: ColorRect
var _is_transitioning: bool = false

func _ready():
	_setup_transition_layer()

## 设置过渡动画层
func _setup_transition_layer():
	_transition_layer = CanvasLayer.new()
	_transition_layer.layer = 100  # 确保在最上层
	add_child(_transition_layer)

	_transition_rect = ColorRect.new()
	_transition_rect.color = Color.BLACK
	_transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_rect.modulate.a = 0.0  # 初始透明
	_transition_layer.add_child(_transition_rect)

## 切换到主菜单
func go_to_main_menu():
	await _change_scene(MAIN_MENU_SCENE)

## 切换到游戏场景
func go_to_game():
	await _change_scene(GAME_SCENE)

## 带过渡效果的场景切换
## @param scene_path: String - 目标场景路径
func _change_scene(scene_path: String) -> void:
	if _is_transitioning:
		return

	_is_transitioning = true

	# 淡出 (屏幕变黑)
	var fade_out_tween: Tween = create_tween()
	fade_out_tween.tween_property(_transition_rect, "modulate:a", 1.0, FADE_DURATION)
	await fade_out_tween.finished

	# 切换场景
	var error: int = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Failed to change scene to: " + scene_path)
		_is_transitioning = false
		return

	# 等待一帧确保新场景加载完成
	await get_tree().process_frame

	# 淡入 (屏幕显示)
	var fade_in_tween: Tween = create_tween()
	fade_in_tween.tween_property(_transition_rect, "modulate:a", 0.0, FADE_DURATION)
	await fade_in_tween.finished

	_is_transitioning = false

## 快速切换场景 (无动画)
func change_scene_immediate(scene_path: String):
	get_tree().change_scene_to_file(scene_path)
