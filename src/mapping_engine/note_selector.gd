extends TextureRect

var note : RhythmGameUtils.Note

var option_button : OptionButton

signal note_deleted(note_obj, note_sprite)

# Called when the node enters the scene tree for the first time.
func _ready():
	# print($OptionButton.get_selected_id())
	option_button = $OptionButton
	if note:
		$Label.text = str(note.start_time)

func set_note_name():
	$Label.text = str(note.start_time)
	match $OptionButton.get_selected_id():
		RhythmGameUtils.NOTES.A: note.note_name = RhythmGameUtils.NOTES.A
		RhythmGameUtils.NOTES.B: note.note_name = RhythmGameUtils.NOTES.B
		RhythmGameUtils.NOTES.C: note.note_name = RhythmGameUtils.NOTES.C
		RhythmGameUtils.NOTES.D: note.note_name = RhythmGameUtils.NOTES.D
		RhythmGameUtils.NOTES.E: note.note_name = RhythmGameUtils.NOTES.E

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			emit_signal("note_deleted", note, self)
			self.queue_free()

func _on_option_button_item_selected(index):
	# print(index)
	set_note_name()
