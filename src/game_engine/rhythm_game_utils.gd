extends Node

# note data
# duration of a note doesnt matter
enum NOTE_TYPES {NORMAL, HOLD}
# sorta analagous to actual notes (B, C, C#, etc)
enum NOTES {A, B, C, D, E}

enum HIT_RESULTS {NO_HIT, HIT, PERFECT}

# visual stuff
# This reallllly shouldn't be hardcoded but we ball i guess
var note_sprite : PackedScene = preload("res://src/note_sprite.tscn")

# we hit this note when it needs to be hit
class Note:
	var note_name : NOTES
	var start_time : float
	var note_type : NOTE_TYPES
	var already_hit : bool
	
	func _init(note_name, start_time):
		self.note_name = note_name
		self.start_time = start_time
		self.note_type = NOTE_TYPES.NORMAL
		self.already_hit = false
	
	# returns three values, no hit, hit, or perfect
	func check_hit(time_hit : float) -> HIT_RESULTS:
		#print(time_hit, " ", self.start_time)
		if time_hit >= start_time - GameManager.perfect_hit_window and time_hit <= start_time + GameManager.perfect_hit_window:
			return HIT_RESULTS.PERFECT
		if time_hit >= start_time - GameManager.hit_window and time_hit <= start_time + GameManager.hit_window:
			return HIT_RESULTS.HIT
		return HIT_RESULTS.NO_HIT

# we hold this note for as long as it takes
class HoldNote extends Note:
	var end_time : float
	func _init(note_name, start_time, end_time):
		super._init(note_name, start_time)
		self.note_type = NOTE_TYPES.HOLD
		self.end_time = end_time

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
					"A": note_name = NOTES.A
					"B": note_name = NOTES.B
					"C": note_name = NOTES.C
					"D": note_name = NOTES.D
					"E": note_name = NOTES.E
				var note_start_time : float = note_data["start_time"]
				
				# Offset is baked at runtime for the player.
				note_array.append(RhythmGameUtils.Note.new(note_name, note_start_time + data_received["offset"]))
			
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
		NOTES.A: new_note.get_node("NoteLabel").text = "A"
		NOTES.B: new_note.get_node("NoteLabel").text = "B"
		NOTES.C: new_note.get_node("NoteLabel").text = "C"
		NOTES.D: new_note.get_node("NoteLabel").text = "D"
		NOTES.E: new_note.get_node("NoteLabel").text = "E"
	# set correct note position (hardcoded for now)
	new_note.position.y = GameManager.note_vertical_offset
	add_child(new_note)
	
	return [note_obj, new_note]
