extends DeltascriptTagDialogueBase

var dialogue_prefab = preload("res://src/cutscenes/DialogueBox.tscn")

func _line_start():
	
	var current_dialogue = dialogue_prefab.instantiate();
	current_dialogue.word_text = line_text
	current_dialogue.name_label = event_player.get_event_metadata("Speaker")
	
	UniversalCanvas.add_child.call_deferred(current_dialogue)
	current_dialogue.dialogue_closed.connect(_advance_text)

func _advance_text():
	goto_next_line()
