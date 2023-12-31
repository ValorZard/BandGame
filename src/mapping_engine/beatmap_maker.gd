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

@export var measure_bar : PackedScene = preload("res://src/mapping_engine/measure_bar.tscn")

# note timelien

var note_timeline : NoteTimeline

var note_selector : PackedScene = load("res://src/mapping_engine/note_selector.tscn")

var timeline_zoom : int = 10

var time_elapsed : float = 0 # keeps track of song playing

# offset in mapping changes when the audio file plays back.
var time_offset_ms : float = 0

# music file
var path_to_music_file : StringName = "res://assets/audio/MUSCMisc_Metronome a 120bpm (ID 0468)_BSB.wav"

# Called when the node enters the scene tree for the first time.
func _ready():
	$HBoxContainer/SongLengthLineEdit.text = str(song_length)
	$HBoxContainer/MeasureSubdivisionLineEdit.text = str(measure_subdivisions)
	$HBoxContainer/BPMLineEdit.text = str(beats_per_minute)
	$TimeSignatureManager/VBoxContainer/NumbOfNotesInMeasureLineEdit.text = str(number_of_notes_in_measure)
	$TimeSignatureManager/VBoxContainer/NoteValueLineEdit.text = str(note_value)
	$HBoxContainer/ZoomEdit.text = str(timeline_zoom)
	$HBoxContainer/TimeOffset.text = str(time_offset_ms)
	note_timeline = $ScrollContainer/NoteTimeline
	update_timeline()
	load_beatmap_to_edit(beatmap_file_path)
	

func update_timeline():
	# set size of the note timeline
	$ScrollContainer/NoteTimeline.custom_minimum_size.x = length_of_note * song_length * timeline_zoom
	# clear out previous formatting
#	for node in $ScrollContainer/NoteTimeline.get_children():
#		if node.is_in_group("formatting"):
#			node.queue_free()
	# put out measure bars
	var beats_per_second : float = beats_per_minute / 60.0
	print(beats_per_second)
	var number_of_measures_in_song : float = song_length / beats_per_second
	
	var i = 0
#	while (i < number_of_measures_in_song):
#		var measure_bar_instance := measure_bar.instantiate()
#		measure_bar_instance.position.x = (i * length_of_note * timeline_zoom)
#		measure_bar_instance.add_to_group("formatting")
#		$ScrollContainer/NoteTimeline.add_child(measure_bar_instance)
#		i += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float):
	# scroll the timeline if a song is playing
	if $AudioStreamPlayer.playing:
		time_elapsed += delta
		$ScrollContainer.set_h_scroll(time_elapsed * length_of_note * timeline_zoom)
		# string formatting
		$PlaySongContainer/PlaySongLabel.text = "%10.3f" % time_elapsed

func redraw_timeline():
	for note in note_timeline.note_array:
		note.sprite.position.x = (note.data.start_time / song_length) * $ScrollContainer/NoteTimeline.custom_minimum_size.x

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
		print(beats_per_minute)
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
	
func _on_time_offset_text_changed(new_text):
	if new_text.is_valid_float():
		#for note in note_timeline.note_array:
		#	note[0].start_time -= time_offset_ms * 0.001
		#	note[0].start_time += time_offset_ms * 0.001
		
		time_offset_ms = float(new_text)
		#update_timeline()

func export_beatmap():
	var beatmap_file = FileAccess.open(beatmap_file_path, FileAccess.WRITE)
	var note_array := note_timeline.note_array
	
	var beatmap_dictionary : Dictionary = {"music-file" : path_to_music_file, "time-offset-ms" : time_offset_ms, "notes" : []}
	
	for note in note_array:
		var note_data : RhythmGameUtils.NoteData = note.data
		# JSON provides a static method to serialized JSON string.
		var note_name_string := ""
		# represent notes as the actual keys on the keyboard your hitting
		match note_data.note_name:
			RhythmGameUtils.NOTES.NOTE1: note_name_string = "1"
			RhythmGameUtils.NOTES.NOTE2: note_name_string = "2"
			RhythmGameUtils.NOTES.NOTE3: note_name_string = "3"
			RhythmGameUtils.NOTES.NOTE4: note_name_string = "4"
		var note_dictionary : Dictionary = {"name" : note_name_string, "start_time" : note_data.start_time}
		beatmap_dictionary["notes"].append(note_dictionary)
	
	var json_string = JSON.stringify(beatmap_dictionary)
	print(beatmap_dictionary)
	# Store the save dictionary as a new line in the save file.
	beatmap_file.store_line(json_string)

# returns a note array, with each element in the array being a tuple of a note object and its sprite represenation
func load_beatmap_to_edit(beatmap_file_path : String):
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
				path_to_music_file = data_received["music-file"]
				time_offset_ms = data_received["time-offset-ms"]
				print(path_to_music_file)
				for note_json_data in data_received["notes"]:
					# parse each note and convert into actual note object
					var note_name : RhythmGameUtils.NOTES
					match note_json_data["name"]:
						"1": note_name = RhythmGameUtils.NOTES.NOTE1
						"2": note_name = RhythmGameUtils.NOTES.NOTE2
						"3": note_name = RhythmGameUtils.NOTES.NOTE3
						"4": note_name = RhythmGameUtils.NOTES.NOTE4
					var note_start_time : float = note_json_data["start_time"]
					var new_note = RhythmGameUtils.NoteData.new(note_name, note_start_time)
					note_array.append(new_note)
					#print(new_note.note_name, ",  ", new_note.start_time)
					note_timeline.raw_note_times[new_note.start_time] = true
				# convert note array from array of note data to array of NoteObjects
				# each member in the note array is a 2-tuple of [NoteObject, NoteSprite]
				note_array = note_array.map(note_selector_spawner)
			else:
				print("Unexpected data")
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", content, " at line ", json.get_error_line())
		# if this somehow fails, the note array will just be empty
		note_timeline.note_array = note_array
	else: 
		pass

func note_selector_spawner(note_data : RhythmGameUtils.NoteData):
	# Spawns a note sprite instance for each note data object in the map array.
	var note_sprite = note_selector.instantiate()
	#print(note_sprite.option_button)
	# set note data
	note_sprite.note_data = note_data
	# set up note sprite signals
	note_sprite.note_deleted.connect(note_timeline.delete_note)
	# set correct note position (hardcoded for now)
	# put the note sprite on the right place in the timeline while keeping it centered
	
	note_sprite.position.x = (note_sprite.note_data.start_time / song_length) * $ScrollContainer/NoteTimeline.custom_minimum_size.x
	
	note_sprite.position.y = note_timeline.size.y / 2
	note_timeline.add_child(note_sprite)
	# set the correct note label
	match note_sprite.note_data.note_name:
		RhythmGameUtils.NOTES.NOTE1: note_sprite.option_button.selected = RhythmGameUtils.NOTES.NOTE1
		RhythmGameUtils.NOTES.NOTE2: note_sprite.option_button.selected = RhythmGameUtils.NOTES.NOTE2
		RhythmGameUtils.NOTES.NOTE3: note_sprite.option_button.selected = RhythmGameUtils.NOTES.NOTE3
		RhythmGameUtils.NOTES.NOTE4: note_sprite.option_button.selected = RhythmGameUtils.NOTES.NOTE4
	
	return RhythmGameUtils.NoteObject.new(note_sprite.note_data, note_sprite)

func _on_test_button_button_down():
	SceneSwitcher.goto_edited_song(beatmap_file_path)

func _on_play_button_button_down():
	$AudioStreamPlayer.play()
	# start playing the timeline from the start
	$ScrollContainer.set_h_scroll(0)
	time_elapsed = 0


func _on_stop_button_button_down():
	$AudioStreamPlayer.stop()



