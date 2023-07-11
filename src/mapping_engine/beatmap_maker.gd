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

var note_timeline : NoteTimeline

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/SongLengthLineEdit.text = str(song_length)
	$HBoxContainer/MeasureSubdivisionLineEdit.text = str(measure_subdivisions)
	$HBoxContainer/BPMLineEdit.text = str(beats_per_minute)
	$TimeSignatureManager/VBoxContainer/NumbOfNotesInMeasureLineEdit.text = str(number_of_notes_in_measure)
	$TimeSignatureManager/VBoxContainer/NoteValueLineEdit.text = str(note_value)
	note_timeline = $ScrollContainer/NoteTimeline
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


func _on_export_button_button_down():
	export_beatmap()

func export_beatmap():
	var beatmap_file = FileAccess.open("user://new_beatmap.json", FileAccess.WRITE)
	var note_array := note_timeline.note_array
	
	var beatmap_dictionary : Dictionary = {"notes" : []}
	
	for note in note_array:
		var note_obj : RhythmGameUtils.Note = note[0]
		# JSON provides a static method to serialized JSON string.
		var note_name_string := ""
		match note_obj.note_name:
			RhythmGameUtils.NOTES.A: note_name_string = "A"
			RhythmGameUtils.NOTES.B: note_name_string = "B"
			RhythmGameUtils.NOTES.C: note_name_string = "C"
			RhythmGameUtils.NOTES.D: note_name_string = "D"
			RhythmGameUtils.NOTES.E: note_name_string = "E"
		var note_dictionary : Dictionary = {"name" : note_name_string, "start_time" : note_obj.start_time}
		beatmap_dictionary["notes"].append(note_dictionary)
	
	var json_string = JSON.stringify(beatmap_dictionary)
	print(beatmap_dictionary)
	# Store the save dictionary as a new line in the save file.
	beatmap_file.store_line(json_string)
