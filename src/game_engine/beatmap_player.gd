extends Node2D

class_name BeatmapPlayer

var time_elapsed_since_start : float = 0

# hit window stuff (in seconds)
var view_window : float = 1 # from now to now + view window, thats the notes that will show

# note managements
@export var note_array : Array
var beats_per_second : float 

# actual beat map
# this is meant to be overridden
# YOU SHOULD NOT LAUNCH THIS SCENE WITHOUT HAVING A BEATMAP SELECTED, ELSE IT WILL CRASH
@export var beatmap_file_path : StringName = ""

# score management:
var score : int

# audio stuff:
@export var audio_offset_s : float = 0.0
var song_finished := false

# visual stuff
# ---------------
# don't check at just beat, because each beat is a measure, you want subdivisions
# but every beat/measure want to draw a line or just make it easier to organize on screen
# mostly visual, not that important, just juice/polish
@export var beats_per_minute : float = 112 

# This reallllly shouldn't be hardcoded but we ball i guess
var note_sprite : PackedScene = preload("res://src/note_sprite.tscn")

# move to next scene
@export var next_button_path : NodePath
@export var scene_to_change_to : PackedScene

# check if this is being edited, if so, we should turn on editor stuff
@export var is_being_edited := false

# how the note array works if its a single track game
# only care about notes charted, notes can happen at any time
# (note_type, start_time, note)
# (0.0, X)
# (0.25, X)
# (0.7, X)
# 
# still need to figure out how holding down a note would work
# would have to have seperate code and implementation for it
# maybe you can make the middle 

# Called when the node enters the scene tree for the first time.
func _ready():	
	# make sure there's a valid beatmap_file_path
	assert(beatmap_file_path != "")
	
	$HitZone.position.x = GameManager.hit_zone_left_offset
	$HitZone.position.y = get_viewport_rect().size.y / 2
	note_array = load_beatmap_to_play(beatmap_file_path)
	# if it isn't being edited, only show button once song is done
	if(!is_being_edited):
		$NextButton.visible = false
	$NextButton.connect("button_up", go_to_next_scene)
	# make audio player signal that its finished
	$AudioStreamPlayer.connect("finished", _on_audio_stream_player_finished)

func go_to_next_scene():
	if(!is_being_edited):
		SceneSwitcher.goto_packed_scene(scene_to_change_to)
	else:
		# go edit the beatmap file
		SceneSwitcher.goto_editor(beatmap_file_path)


# returns a note array, with each element in the array being a tuple of a note object and its sprite represenation
func load_beatmap_to_play(beatmap_file_path : String) -> Array:
	var note_array : Array
	# file stuff
	var file = FileAccess.open(beatmap_file_path, FileAccess.READ)
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
					"1": note_name = RhythmGameUtils.NOTES.NOTE1
					"2": note_name = RhythmGameUtils.NOTES.NOTE2
					"3": note_name = RhythmGameUtils.NOTES.NOTE3
					"4": note_name = RhythmGameUtils.NOTES.NOTE4
				var note_start_time : float = note_data["start_time"]
				
				# Offset is baked at runtime for the player.
				note_array.append(RhythmGameUtils.Note.new(note_name, note_start_time + data_received["time-offset-ms"]))
			
			# each member in the note array is a 2-tuple of [NoteObject, NoteSprite]
			note_array = note_array.map(note_spawner)
			
		else:
			print("Unexpected data")
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", content, " at line ", json.get_error_line())
	# if this somehow fails, the note array will just be empty
	
	# Sort note array by duration. Rest of engine assumes this to be true.
	note_array.sort_custom(func(a, b) : return b[0].start_time > a[0].start_time)
	return note_array

func note_spawner(note_obj : RhythmGameUtils.Note):
	# Spawns a note sprite instance for every note object in the map array.
	var new_note = note_sprite.instantiate()
	# set the correct note label
	match note_obj.note_name:
		RhythmGameUtils.NOTES.NOTE1: new_note.get_node("NoteLabel").text = "D"
		RhythmGameUtils.NOTES.NOTE2: new_note.get_node("NoteLabel").text = "F"
		RhythmGameUtils.NOTES.NOTE3: new_note.get_node("NoteLabel").text = "J"
		RhythmGameUtils.NOTES.NOTE4: new_note.get_node("NoteLabel").text = "K"
	# set correct note position (hardcoded for now)
	new_note.position.y = GameManager.note_vertical_offset
	
	# arbitrary position off screen
	new_note.position.x = -1000
	add_child(new_note)
	
	return [note_obj, new_note]

func _on_audio_stream_player_finished():
	song_finished = true
	$NextButton.visible = true

func delete_note(note_pair):
	# Stops a note from being hit twice, removing the visual instance of a note when it is.
	note_pair[0].already_hit = true
	note_pair[1].queue_free()

func hit_note(note_name : RhythmGameUtils.NOTES, note_array : Array, current_time : float):
	$DebugNoteLabel.text = str("note name ", note_name, " at: ",  "%10.3f" % current_time)
	
	# go through every single note on screen and see which one is close enough to hit, and wheather it matches the note the player hit
	for note in range(len(note_array)):
		if !note_array[note][0].already_hit:
			if (note_array[note][0].start_time + GameManager.hit_window) < (current_time - GameManager.WAIT_CLEAR):
				# Handles ignoring notes that were missed.
				# FIXED 07/11/22: WAIT_CLEAR is used as an offset to wait until missed notes are fully passed before visually clearing them.
				delete_note(note_array[note])
				
			elif note_array[note][0].note_name == note_name:
				var hit_result = note_array[note][0].check_hit(current_time)
				if hit_result != RhythmGameUtils.HIT_RESULTS.NO_HIT:
					if hit_result == RhythmGameUtils.HIT_RESULTS.PERFECT:
						score += GameManager.PERFECT_SCORE
					elif hit_result == RhythmGameUtils.HIT_RESULTS.HIT:
						score += GameManager.NORMAL_SCORE
						
					delete_note(note_array[note])
					$Score.text = str(score)
					note_array.remove_at(note)
					
				return


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_elapsed_since_start += delta
	
	# this is straight up the less janky way i can think of for the audio to not constantly loop
	if time_elapsed_since_start >= audio_offset_s and time_elapsed_since_start <= audio_offset_s + 1 and !$AudioStreamPlayer.playing:
		$AudioStreamPlayer.play()
	
	if Input.is_action_just_pressed("note1"):
		#print("note1")
		# we want to calculate the time missed by to make the note perfect
		# we want to center the note in the middle of the beat
		hit_note(RhythmGameUtils.NOTES.NOTE1, note_array, time_elapsed_since_start)
	if Input.is_action_just_pressed("note2"):
		#print("note2")
		hit_note(RhythmGameUtils.NOTES.NOTE2, note_array, time_elapsed_since_start)
	if Input.is_action_just_pressed("note3"):
		#print("note3")
		hit_note(RhythmGameUtils.NOTES.NOTE3, note_array, time_elapsed_since_start)
	if Input.is_action_just_pressed("note4"):
		#print("note4")
		hit_note(RhythmGameUtils.NOTES.NOTE4, note_array, time_elapsed_since_start)
	
	# visual stuff
	
	# move the notes across the screen one by one
	for note in note_array:
		# note is a 2-tuple of [NoteObject, NoteSprite]
		if !note[0].already_hit and note[0].start_time - view_window <= time_elapsed_since_start:
			# display the note position on screen based on the ratio between where the note is spawned and where its supposed to be hit
			# if its 0, its all the way to the right, and visa versa
			var screen_position_ratio : float = (-(note[0].start_time - view_window - time_elapsed_since_start)/view_window)
			note[1].position.x = get_viewport_rect().size.x - screen_position_ratio * get_viewport_rect().size.x + GameManager.hit_zone_left_offset
		
