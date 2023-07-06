extends TextureRect

var note_array : Array


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("I've been clicked at: ", event.position)
			var note_obj : RhythmGameUtils.Note = RhythmGameUtils.Note.new(RhythmGameUtils.NOTES.A, 10)
			var note_sprite := RhythmGameUtils.note_sprite.instantiate()
			note_sprite.position = event.position
			add_child(note_sprite)
			note_array.append([note_obj, note_sprite])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
