extends Node

# Event Bus for global signals

# Game Flow
signal game_started
signal turn_changed(side)
signal game_over(winner)
signal check_detected(side)
signal undo_executed
signal board_refreshed(board_logic)

# Input & Interaction
signal piece_selected(piece_data, pos)
signal grid_clicked(pos)

# Visual Updates
signal update_highlights(selected_pos, valid_moves)
signal clear_highlights
signal move_executed(from, to)

# UI
signal history_updated(move_name)
