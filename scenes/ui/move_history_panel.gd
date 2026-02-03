extends Panel

@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var moves_container: VBoxContainer = $ScrollContainer/MovesContainer

func _ready():
	EventBus.history_updated.connect(_on_history_updated)
	EventBus.game_started.connect(_clear_history)
	EventBus.undo_executed.connect(_on_undo_executed)

func _on_history_updated(move_name: String):
	var label = Label.new()
	label.text = move_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	moves_container.add_child(label)
	
	# Auto scroll to bottom
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _clear_history():
	for child in moves_container.get_children():
		child.queue_free()

func _on_undo_executed():
	# Remove last child
	var children = moves_container.get_children()
	if children.size() > 0:
		children.back().queue_free()
