extends Control
## 游戏内UI
##
## 管理游戏状态显示、控制按钮和弹窗对话框。

@onready var status_panel: PanelContainer = $MarginContainer/MainPanel/VBoxContainer/StatusPanel
@onready var history_panel: PanelContainer = $MarginContainer/MainPanel/VBoxContainer/HistoryPanel
@onready var new_game_button: Button = $MarginContainer/MainPanel/VBoxContainer/ButtonsContainer/NewGameButton
@onready var undo_button: Button = $MarginContainer/MainPanel/VBoxContainer/ButtonsContainer/UndoButton
@onready var menu_button: Button = $MarginContainer/MainPanel/VBoxContainer/ButtonsContainer/MenuButton

# 弹窗引用
@onready var pause_dialog: Control = $PauseDialog
@onready var game_over_dialog: Control = $GameOverDialog
@onready var game_over_title: Label = $GameOverDialog/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var game_over_message: Label = $GameOverDialog/CenterContainer/Panel/VBoxContainer/MessageLabel

func _ready():
	# 连接按钮信号
	new_game_button.pressed.connect(_on_new_game_pressed)
	undo_button.pressed.connect(_on_undo_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# 连接EventBus信号
	EventBus.pause_requested.connect(_show_pause_dialog)
	EventBus.game_over.connect(_on_game_over)
	EventBus.game_started.connect(_on_game_started)
	
	# 初始隐藏弹窗
	if pause_dialog:
		pause_dialog.visible = false
	if game_over_dialog:
		game_over_dialog.visible = false

func _on_new_game_pressed():
	AudioManager.play_move()
	GameManager.start_new_game()

func _on_undo_pressed():
	AudioManager.play_move()
	GameManager.undo_last_move()

func _on_menu_pressed():
	AudioManager.play_move()
	_show_pause_dialog()

func _show_pause_dialog():
	if pause_dialog:
		pause_dialog.visible = true
		# 暂停游戏输入
		get_tree().paused = false  # 我们不使用树暂停，只是显示菜单

func _hide_pause_dialog():
	if pause_dialog:
		pause_dialog.visible = false

func _on_game_over(winner: Constants.Side):
	if game_over_dialog:
		var winner_text = "红方" if winner == Constants.Side.RED else "黑方"
		game_over_title.text = winner_text + "获胜!"
		game_over_message.text = "恭喜" + winner_text + "取得胜利"
		
		# 显示弹窗动画
		game_over_dialog.visible = true
		game_over_dialog.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(game_over_dialog, "modulate:a", 1.0, 0.3)

func _on_game_started():
	# 隐藏游戏结束弹窗
	if game_over_dialog:
		game_over_dialog.visible = false
	if pause_dialog:
		pause_dialog.visible = false

# 暂停对话框按钮回调
func _on_resume_pressed():
	AudioManager.play_move()
	_hide_pause_dialog()

func _on_restart_pressed():
	AudioManager.play_move()
	_hide_pause_dialog()
	GameManager.start_new_game()

func _on_return_menu_pressed():
	AudioManager.play_move()
	_hide_pause_dialog()
	SceneManager.go_to_main_menu()

# 游戏结束对话框按钮回调
func _on_play_again_pressed():
	AudioManager.play_move()
	GameManager.start_new_game()

func _on_exit_to_menu_pressed():
	AudioManager.play_move()
	SceneManager.go_to_main_menu()
