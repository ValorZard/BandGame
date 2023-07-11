extends Sprite2D

var note : RhythmGameUtils.Note

# Called when the node enters the scene tree for the first time.
func _ready():
	print($OptionButton.get_selected_id())
	set_note_name()

func set_note_name():
	match $OptionButton.get_selected_id():
		RhythmGameUtils.NOTES.A: note.note_name = RhythmGameUtils.NOTES.A
		RhythmGameUtils.NOTES.B: note.note_name = RhythmGameUtils.NOTES.B
		RhythmGameUtils.NOTES.C: note.note_name = RhythmGameUtils.NOTES.C
		RhythmGameUtils.NOTES.D: note.note_name = RhythmGameUtils.NOTES.D
		RhythmGameUtils.NOTES.E: note.note_name = RhythmGameUtils.NOTES.E

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_option_button_item_selected(index):
	print(index)
	set_note_name()
