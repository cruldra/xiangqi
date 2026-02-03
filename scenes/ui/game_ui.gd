extends Control

func _on_new_game_pressed():
	GameManager.start_new_game()

func _on_undo_pressed():
	GameManager.undo_last_move()
