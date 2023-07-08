extends Control

class_name BeatmapMaker

@export var beats_per_minute : float = 112 
@export var song_length : float = 60. # in seconds
@export var measure_subdivisions : int = 1 # how many notes fit in one measure
# top part of a time signature
# number of notes in a measure
@export var number_of_notes_in_measure : int = 4 
# bottom part of a time signature
# the note value that the signature is counting. 
# This number is always a power of 2, usually 2, 4, or 8. 
# 2 corresponds to the half note (minim), 4 to the quarter note (crotchet), 8 to the eighth note (quaver).
@export var note_value : int = 4 
@export var length_of_note : float = 20 # how big a note is on screen


# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/SongLengthLineEdit.text = str(song_length)
	$HBoxContainer/MeasureSubdivisionLineEdit.text = str(measure_subdivisions)
	$HBoxContainer/BPMLineEdit.text = str(beats_per_minute)
	$TimeSignatureManager/VBoxContainer/NumbOfNotesInMeasureLineEdit.text = str(number_of_notes_in_measure)
	$TimeSignatureManager/VBoxContainer/NoteValueLineEdit.text = str(note_value)
	update_timeline()

func update_timeline():
	# set size of the note timeline
	$ScrollContainer/NoteTimeline.custom_minimum_size.x = length_of_note * measure_subdivisions * song_length 
	#print("number of notes in measure: ", number_of_notes_in_measure, ", note_value: ", note_value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_song_length_line_edit_text_changed(new_text : String):
	if new_text.is_valid_float():
		song_length = float(new_text)
		update_timeline()


func _on_measure_subdivision_line_edit_text_changed(new_text):
	if new_text.is_valid_int():
		measure_subdivisions = int(new_text)
		update_timeline()


func _on_bpm_line_edit_text_changed(new_text):
	if new_text.is_valid_float():
		beats_per_minute = float(new_text)
		update_timeline()


func _on_number_of_notes_in_measure_text_changed(new_text):
	if new_text.is_valid_int():
		number_of_notes_in_measure = int(new_text)
		update_timeline()


func _on_note_value_text_changed(new_text):
	if new_text.is_valid_int():
		note_value = int(new_text)
		update_timeline()
