extends Node2D
class_name MidiMapEngine

@export var time_snap: float = 0.1
@export_file("*.json") var midi_parsed_file: String

var notes = Dictionary()

var midi_notes: Array[MidiMapEngineNote] = []

var MIDIENGINENOTE = preload("res://src/midi_map_engine/midi_map_engine_notes/midi_map_engine_note.tscn")

var the_min = INF
var the_max = 0

var index_colldown = {0:0.0,1:0.0,2:0.0,3:0.0}
@onready var index_dict = {0:$notes/Upper, 1:$notes/MidUpper,2:$notes/MidLower, 3:$notes/Lower}

func midi_to_index(midi_n,number_of_indexes=4):
	var range_delta = (the_max-the_min)/number_of_indexes
	
	return clamp(int((midi_n-the_min)/range_delta),0,number_of_indexes-1)

func _ready():
	process_parsed_midi_file()
	$Timer.wait_time = time_snap
	#_on_start_music_timeout()
	
func in_allowed_range(midi_n):
	return midi_n > 70 and midi_n < 78
	#return midi_n < 40
	#return true
	
func process_parsed_midi_file():
	#var notes = Dictionary()
	var the_file = FileAccess.open(midi_parsed_file,FileAccess.READ)
	var the_json = JSON.parse_string(the_file.get_as_text())
	for track in the_json['tracks']:
		for note in track['notes']:
			var time = str(snapped(note['time'],time_snap))
			
			if time not in notes: 
				notes[time] = []
			notes[time].append([note["midi"], note["duration"]])
			if not in_allowed_range(note["midi"]): continue
			the_max = max(the_max,note["midi"])
			the_min = min(the_min,note["midi"])
	#print(the_max," ",the_min)
	#print(notes)

#adapted from: https://github.com/rfiedorowicz/Godot_midi_json_animation_tutorial/blob/master/Stage.tscn
var effective_elapsed_time = 0.0
var music_rate = 1.0

func _process(delta):
	effective_elapsed_time += delta*music_rate
	
	for i in index_colldown:
		index_colldown[i] = max(0.0,index_colldown[i]-delta*music_rate)

func _on_timer_timeout():
	var current_time = str(snapped(effective_elapsed_time,time_snap))
	if current_time in notes:
		var to_parse = notes[current_time]
		for each in to_parse:
			print(each[0])
			if not in_allowed_range(each[0]): continue
			var i = midi_to_index(each[0])
			if index_colldown[i] > 0.0: continue
			
			spawn_new_note(i,each[1])
		"""
		var create_new = false
		for each in to_parse:
			if each[0] == 88:
				create_new = true
				break
		if create_new:
			var new_note = MIDIENGINENOTE.instantiate() as MidiMapEngineNote
			new_note.set_polygon()
			$notes/Upper.add_child(new_note)
			new_note.start()
		"""

func spawn_new_note(i,time):
	index_colldown[i] = time+0.5
	var new_note = MIDIENGINENOTE.instantiate() as MidiMapEngineNote
	new_note.set_polygon()
	
	var parent = index_dict[i] as Path2D
	if parent == null: return
	parent.add_child(new_note)
	new_note.start()
	

func _on_start_music_timeout():
	$AudioStreamPlayer.playing=true
