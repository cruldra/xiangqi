extends Control
## 主菜单场景
##
## 游戏启动后的第一个场景，提供游戏模式选择和设置入口。

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleContainer/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/TitleContainer/SubtitleLabel
@onready var pvp_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/PvPButton
@onready var pve_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/PvEButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/QuitButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	# 入场动画
	_play_entrance_animation()
	
	# 连接按钮信号
	pvp_button.pressed.connect(_on_pvp_pressed)
	pve_button.pressed.connect(_on_pve_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# 设置按钮悬停音效 (如果需要)
	_setup_button_hover_effects()

func _play_entrance_animation():
	# 初始状态：透明
	modulate.a = 0.0
	
	# 标题从上方滑入
	if title_label:
		title_label.position.y -= 50
	if subtitle_label:
		subtitle_label.modulate.a = 0
	
	# 按钮初始位置
	var buttons = [pvp_button, pve_button, quit_button]
	for btn in buttons:
		if btn:
			btn.modulate.a = 0
			btn.position.x -= 30
	
	# 播放动画
	var tween = create_tween()
	tween.set_parallel(false)
	
	# 整体淡入
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
	# 标题动画
	if title_label:
		tween.tween_property(title_label, "position:y", title_label.position.y + 50, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 副标题淡入
	if subtitle_label:
		tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.3)
	
	# 按钮依次滑入
	tween.set_parallel(true)
	var delay = 0.0
	for btn in buttons:
		if btn:
			tween.tween_property(btn, "modulate:a", 1.0, 0.3).set_delay(delay)
			tween.tween_property(btn, "position:x", btn.position.x + 30, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(delay)
			delay += 0.1

func _setup_button_hover_effects():
	var buttons = [pvp_button, pve_button, quit_button]
	for btn in buttons:
		if btn:
			btn.mouse_entered.connect(_on_button_hover.bind(btn))
			btn.focus_entered.connect(_on_button_hover.bind(btn))

func _on_button_hover(button: Button):
	# 轻微缩放效果
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_pvp_pressed():
	AudioManager.play_move()
	GameManager.is_vs_ai_mode = false
	SceneManager.go_to_game()

func _on_pve_pressed():
	AudioManager.play_move()
	GameManager.is_vs_ai_mode = true
	SceneManager.go_to_game()

func _on_quit_pressed():
	get_tree().quit()

## 处理键盘输入 (ESC退出等)
func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()
