extends Control

@onready var turn_label: Label = $VBoxContainer/TurnLabel
@onready var check_label: Label = $VBoxContainer/CheckLabel

func _ready():
	EventBus.turn_changed.connect(_on_turn_changed)
	EventBus.check_detected.connect(_on_check_detected)
	EventBus.game_over.connect(_on_game_over)
	EventBus.game_started.connect(_on_game_started)
	
	# Initial state
	check_label.text = ""
	_update_turn_label(Constants.Side.RED)

func _on_turn_changed(side: Constants.Side):
	_update_turn_label(side)
	check_label.text = "" # Clear check warning on turn switch

func _on_check_detected(side: Constants.Side):
	check_label.text = "将军!"
	check_label.modulate = Color.RED

func _on_game_over(winner: Constants.Side):
	var winner_text = "红方" if winner == Constants.Side.RED else "黑方"
	check_label.text = winner_text + " 胜!"
	check_label.modulate = Color.YELLOW

func _on_game_started():
	check_label.text = ""
	_update_turn_label(Constants.Side.RED)

func _update_turn_label(side: Constants.Side):
	if side == Constants.Side.RED:
		turn_label.text = "红方回合"
		turn_label.modulate = Color.RED
	else:
		turn_label.text = "黑方回合"
		turn_label.modulate = Color.BLACK
