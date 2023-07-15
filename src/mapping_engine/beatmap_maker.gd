extends Control

class_name BeatmapMaker

@export var beats_per_minute : float = 120 
@export var song_length : float = 60. # in seconds
@export var measure_subdivisions : int = 4 # how many notes fit in one measure
# top part of a time signature
# number of notes in a measure
@export var number_of_notes_in_measure : int = 4 
# bottom part of a time signature
# the note value that the signature is counting. 
# This number is always a power of 2, usually 2, 4, or 8. 
# 2 corresponds to the half note (minim), 4 to the quarter note (crotchet), 8 to the eighth note (quaver).
@export var note_value : int = 4
@export var length_of_note : float = 20 # how big a note is on screen

# beatmap stuff

@export var beatmap_file_path : StringName = "user://new_beatmap.json"

@export var beatmap_player : PackedScene = load("res://src/game_engine/beatmap.tscn")

# note timelien

var note_timeline : NoteTimeline

var note_selector : PackedScene = load("res://src/mapping_engine/note_selector.tscn")

var timeline_zoom : int = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/SongLengthLineEdit.text = str(song_length)
	$HBoxContainer/MeasureSubdivisionLineEdit.text = str(measure_subdivisions)
	$HBoxContainer/BPMLineEdit.text = str(beats_per_minute)
	$TimeSignatureManager/VBoxContainer/NumbOfNotesInMeasureLineEdit.text = str(number_of_notes_in_measure)
	$TimeSignatureManager/VBoxContainer/NoteValueLineEdit.text = str(note_value)
	$HBoxContainer/ZoomEdit.text = str(timeline_zoom)
	note_timeline = $ScrollContainer/NoteTimeline
	update_timeline()
	load_beatmap(beatmap_file_path)

func update_timeline():
	# set size of the note timeline
	$ScrollContainer/NoteTimeline.custom_minimum_size.x = length_of_note * song_length * timeline_zoom
	#print("number of notes in measure: ", number_of_notes_in_measure, ", note_value: ", note_value)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	

func redraw_timeline():
	for note in note_timeline.note_array:
		note[1].position.x = (note[0].start_time / song_length) * $ScrollContainer/NoteTimeline.custom_minimum_size.x

func _on_zoom_edit_text_changed(new_text):
	if new_text.is_valid_int() and int(new_text) > 0:
		timeline_zoom = int(new_text)
		update_timeline()
		redraw_timeline()

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
	note_timeline.size.x
	export_beatmap()

func export_beatmap():
	var beatmap_file = FileAccess.open(beatmap_file_path, FileAccess.WRITE)
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

# returns a note array, with each element in the array being a tuple of a note object and its sprite represenation
func load_beatmap(beatmap_file_path : String):
	var note_array : Array
	# file stuff
	var file = FileAccess.open(beatmap_file_path, FileAccess.READ)
	# check if theres anything in the beatmap we can load. if theres nothing, exist
	if file:
		var content = file.get_as_text()
		# json stuff
		var json = JSON.new()
		var error = json.parse(content)
		if error == OK:
			var data_received = json.data
			if typeof(data_received) == TYPE_DICTIONARY:
				# actually convert our json data into usable beatmap data
				for note_data in data_received["notes"]:
					# parse each note and convert into actual note object
					var note_name : RhythmGameUtils.NOTES
					match note_data["name"]:
						"A": note_name = RhythmGameUtils.NOTES.A
						"B": note_name = RhythmGameUtils.NOTES.B
						"C": note_name = RhythmGameUtils.NOTES.C
						"D": note_name = RhythmGameUtils.NOTES.D
						"E": note_name = RhythmGameUtils.NOTES.E
					var note_start_time : float = note_data["start_time"]
					var new_note = RhythmGameUtils.Note.new(note_name, note_start_time)
					note_array.append(new_note)
					#print(new_note.note_name, ",  ", new_note.start_time)
				
				# each member in the note array is a 2-tuple of [NoteObject, NoteSprite]
				note_array = note_array.map(note_spawner)
			else:
				print("Unexpected data")
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", content, " at line ", json.get_error_line())
		# if this somehow fails, the note array will just be empty
		note_timeline.note_array = note_array
	else: 
		pass

func note_spawner(note_obj : RhythmGameUtils.Note):
	# Spawns a note sprite instance for every note object in the map array.
	var note_sprite = note_selector.instantiate()
	#print(note_sprite.option_button)
	# set note data
	note_sprite.note = note_obj
	# set correct note position (hardcoded for now)
	# put the note sprite on the right place in the timeline while keeping it centered
	
	note_sprite.position.x = (note_sprite.note.start_time / song_length) * $ScrollContainer/NoteTimeline.custom_minimum_size.x
	
	note_sprite.position.y = note_timeline.size.y / 2
	note_timeline.add_child(note_sprite)
	# set the correct note label
	match note_sprite.note.note_name:
		RhythmGameUtils.NOTES.A: note_sprite.option_button.selected = RhythmGameUtils.NOTES.A
		RhythmGameUtils.NOTES.B: note_sprite.option_button.selected = RhythmGameUtils.NOTES.B
		RhythmGameUtils.NOTES.C: note_sprite.option_button.selected = RhythmGameUtils.NOTES.C
		RhythmGameUtils.NOTES.D: note_sprite.option_button.selected = RhythmGameUtils.NOTES.D
		RhythmGameUtils.NOTES.E: note_sprite.option_button.selected = RhythmGameUtils.NOTES.E
	
	return [note_sprite.note, note_sprite]

func _on_test_button_button_down():
	# add beatmap player to root
	var beatmap_player_instance : BeatmapPlayer = beatmap_player.instantiate()
	#print(beatmap_player_instance)
	beatmap_player_instance.beatmap_file_path = beatmap_file_path
	get_tree().root.add_child(beatmap_player_instance)
	# remove self from root
	get_tree().root.remove_child(self)



