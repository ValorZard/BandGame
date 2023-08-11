extends Node2D

class_name BeatmapPlayer

var time_elapsed_since_start : float = 0

# hit window stuff (in seconds)
var view_window : float = 1 # from now to now + view window, thats the notes that will show

# note managements
@export var note_array : Array
var beats_per_second : float 

# actual beat map
@export var beatmap_file_path : StringName = "user://new_beatmap.json"

# beatmap editor
@export var beatmap_editor : PackedScene = load("res://src/mapping_engine/beatmap_maker.tscn")

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

var note_sprite

# move to next scene
@export var next_button_path : NodePath
@export var scene_to_change_to : PackedScene

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
	$HitZone.position.x = GameManager.hit_zone_left_offset
	$HitZone.position.y = get_viewport_rect().size.y / 2
	note_array = RhythmGameUtils.load_beatmap_to_play(beatmap_file_path)
#	var button := get_tree().get_current_scene().get_node(next_button_path)
#	if button is Button:
#		button.visible = false
#		button.connect("button_up", switch_scenes)

func switch_scenes():
	get_tree().change_scene_to_packed(scene_to_change_to)


func _on_audio_stream_player_finished():
	song_finished = true
	var button := get_tree().get_current_scene().get_node(next_button_path)
	if button is Button:
		button.visible = true

func delete_note(note_pair):
	# Stops a note from being hit twice, removing the visual instance of a note when it is.
	note_pair[0].already_hit = true
	note_pair[1].queue_free()

func hit_note(note_name : RhythmGameUtils.NOTES, note_array : Array, current_time : float):
	$DebugNoteLabel.text = str("note name ", note_name)
	
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
		
		if note[0].start_time > time_elapsed_since_start:
			# early exit the loop if we've hit a note that shouldn't be displayed, as we have sorted notes by time.
			break


func _on_edit_button_button_down():
	# add beatmap player to root
	var beatmap_editor_instance = beatmap_editor.instantiate()
	beatmap_editor_instance.beatmap_file_path = beatmap_file_path
	#beatmap_editor_instance.load_beatmap(beatmap_file_path)
	get_tree().root.add_child(beatmap_editor_instance)
	# really weird workaround for visual bug
	for node in RhythmGameUtils.get_children():
		node.queue_free()
	# remove self from root
	get_tree().root.remove_child(self)
