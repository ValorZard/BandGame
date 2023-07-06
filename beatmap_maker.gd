extends Control


@export var beats_per_minute : float = 112 
@export var song_length : float = 60. # in seconds
@export var beat_subdivisions : int = 1 # how many notes fit in one beat
@export var length_of_note : float = 20 # how big a note is on screen

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/SongLengthLineEdit.text = str(song_length)
	$HBoxContainer/BeatSubdivisionLineEdit.text = str(beat_subdivisions)
	update_timeline()

func update_timeline():
	# set size of the note timeline
	$ScrollContainer/NoteTimeline.custom_minimum_size.x = length_of_note * beat_subdivisions * song_length 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_song_length_line_edit_text_changed(new_text : String):
	if new_text.is_valid_float():
		song_length = float(new_text)
		update_timeline()


func _on_beat_subdivision_line_edit_text_changed(new_text):
	if new_text.is_valid_int():
		beat_subdivisions = int(new_text)
		update_timeline()
