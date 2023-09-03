extends Node2D

class_name BeatmapPlayer

var time_elapsed_since_start : float = 0

# hit window stuff (in seconds)
var view_window : float = 1 # from now to now + view window, thats the notes that will show

# note managements
var note_array : Array #contains NoteObject only, which are data and visual bundled together 
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
var note1_texture : Texture2D = preload("res://assets/textures/notes/note1.png")
var note2_texture : Texture2D = preload("res://assets/textures/notes/note2.png")
var note3_texture : Texture2D = preload("res://assets/textures/notes/note3.png")
var note4_texture : Texture2D = preload("res://assets/textures/notes/note4.png")

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
	load_beatmap_to_play(beatmap_file_path)
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


# fills up our note array, with each element in the array being a tuple of a note object and its sprite represenation
func load_beatmap_to_play(beatmap_file_path : String):
	# first get an array of all the data
	var note_data_array : Array[RhythmGameUtils.NoteData]
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
			for note_json_data in data_received["notes"]:
				# parse each note and convert into actual note object
				var note_name : RhythmGameUtils.NOTES
				match note_json_data["name"]:
					"1": note_name = RhythmGameUtils.NOTES.NOTE1
					"2": note_name = RhythmGameUtils.NOTES.NOTE2
					"3": note_name = RhythmGameUtils.NOTES.NOTE3
					"4": note_name = RhythmGameUtils.NOTES.NOTE4
				var note_start_time : float = note_json_data["start_time"]
				
				# Offset is baked at runtime for the player.
				note_data_array.append(RhythmGameUtils.NoteData.new(note_name, note_start_time + data_received["time-offset-ms"]))
			
			# each member in the note array is a 2-tuple of [NoteObject, NoteSprite]
			note_array = note_data_array.map(note_sprite_spawner)
			
		else:
			print("Unexpected data")
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", content, " at line ", json.get_error_line())
	# if this somehow fails, the note array will just be empty
	
	# Sort note array by duration. Rest of engine assumes this to be true.
	note_array.sort_custom(func(a, b) : return b.data.start_time > a.data.start_time)

func note_sprite_spawner(note_data: RhythmGameUtils.NoteData):
	# Spawns a note sprite instance for every note object in the map array.
	var new_note_sprite = note_sprite.instantiate()
	# set the correct note label
	match note_data.note_name:
		RhythmGameUtils.NOTES.NOTE1: 
			new_note_sprite.set_texture(note1_texture)
		RhythmGameUtils.NOTES.NOTE2: 
			new_note_sprite.set_texture(note2_texture)
		RhythmGameUtils.NOTES.NOTE3: 
			new_note_sprite.set_texture(note3_texture)
		RhythmGameUtils.NOTES.NOTE4: 
			new_note_sprite.set_texture(note4_texture)
	# set correct note position (hardcoded for now)
	new_note_sprite.position.y = GameManager.note_vertical_offset
	
	# arbitrary position off screen
	new_note_sprite.position.x = -1000
	add_child(new_note_sprite)
	
	return RhythmGameUtils.NoteObject.new(note_data, new_note_sprite)

func _on_audio_stream_player_finished():
	song_finished = true
	$NextButton.visible = true

func delete_note(note_pair):
	# Stops a note from being hit twice, removing the visual instance of a note when it is.
	note_pair.data.already_hit = true
	note_pair.sprite.queue_free()

# this function is kinda broken and needs to be stress tested heavily
# we are doing things here that might break when we least expect it, because we're removing notes while looping through the array
# (it does a little O(N) note array probing)
func hit_note(note_name : RhythmGameUtils.NOTES, note_array : Array, current_time : float):
	$DebugNoteLabel.text = str("hit note name ", note_name, " at: ",  "%10.3f" % current_time)
	
	# go through every single note on screen and see which one is close enough to hit, and wheather it matches the note the player hit
	# we only want to hit ONE NOTE
	var note_index : int = 0
	# store note we want to hit here
	var index_of_note_that_got_hit : int = -1 # if -1 that means we didn't find it
	var min_time_difference : float = 92233720368547758 # abritrarily large number for logic purposes
	while(note_index < len(note_array)):
		# check for out of bounds crash
		if note_index >= len(note_array):
			break
		# want to see if this note even matches up with the note name we hit (note1, 2, 3 etc)
		if note_array[note_index].data.note_name == note_name:
			var time_difference = note_array[note_index].data.check_hit(current_time)
			if time_difference <= GameManager.hit_window:
				if !note_array[note_index].data.already_hit:
					# if we have a note that fits the critera, store it
					# we're going to keep iterating in case we find a better one
					if(min_time_difference > time_difference):
						min_time_difference = time_difference
						index_of_note_that_got_hit = note_index
		note_index += 1
	
	# delete and remove the note that got hit
	if(index_of_note_that_got_hit > -1):
		delete_note(note_array[index_of_note_that_got_hit])
		note_array.remove_at(index_of_note_that_got_hit)
		if min_time_difference <= GameManager.perfect_hit_window:
			score += GameManager.PERFECT_SCORE
		else: # assume that it just got normally hit
			score += GameManager.NORMAL_SCORE
		$Score.text = str(score)

func clean_up_missed_notes(current_time : float):
	var queue_of_notes_missed : Array[RhythmGameUtils.NoteObject]
	for note in note_array:
		if (note.data.start_time + GameManager.hit_window) < (current_time - GameManager.WAIT_CLEAR):
			# Handles ignoring notes that were missed.
			# FIXED 07/11/22: WAIT_CLEAR is used as an offset to wait until missed notes are fully passed before visually clearing them.
			queue_of_notes_missed.append(note)
	
	# remove each note missed from the queue
	for note in queue_of_notes_missed:
		delete_note(note)
		note_array.erase(note)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# TODO: replace with get_playback_position()
	time_elapsed_since_start += delta
	
	# this is straight up the less janky way i can think of for the audio to not constantly loop
	if time_elapsed_since_start >= audio_offset_s and time_elapsed_since_start <= audio_offset_s + 1 and !$AudioStreamPlayer.playing:
		$AudioStreamPlayer.play()
	
	# clean up all of the notes we missed and remove them from the note array
	clean_up_missed_notes($AudioStreamPlayer.get_playback_position())
	
	if Input.is_action_just_pressed("note1"):
		#print("note1")
		# we want to calculate the time missed by to make the note perfect
		# we want to center the note in the middle of the beat
		hit_note(RhythmGameUtils.NOTES.NOTE1, note_array, $AudioStreamPlayer.get_playback_position())
	if Input.is_action_just_pressed("note2"):
		#print("note2")
		hit_note(RhythmGameUtils.NOTES.NOTE2, note_array, $AudioStreamPlayer.get_playback_position())
	if Input.is_action_just_pressed("note3"):
		#print("note3")
		hit_note(RhythmGameUtils.NOTES.NOTE3, note_array, $AudioStreamPlayer.get_playback_position())
	if Input.is_action_just_pressed("note4"):
		#print("note4")
		hit_note(RhythmGameUtils.NOTES.NOTE4, note_array, $AudioStreamPlayer.get_playback_position())
	
	# visual stuff
	
	# move the notes across the screen one by one
	for note in note_array:
		# note is a 2-tuple of [NoteObject, NoteSprite]
		if !note.data.already_hit and note.data.start_time - view_window <= $AudioStreamPlayer.get_playback_position():
			# display the note position on screen based on the ratio between where the note is spawned and where its supposed to be hit
			# if its 0, its all the way to the right, and visa versa
			var screen_position_ratio : float = (-(note.data.start_time - view_window - $AudioStreamPlayer.get_playback_position())/view_window)
			note.sprite.position.x = get_viewport_rect().size.x - screen_position_ratio * get_viewport_rect().size.x + GameManager.hit_zone_left_offset
			# Set y position
			note.sprite.position.y = get_viewport_rect().size.y / 2
