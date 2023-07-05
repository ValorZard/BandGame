extends Node2D

var time_elapsed_since_start : float = 0

# note data
# duration of a note doesnt matter
enum NOTE_TYPES {NORMAL, HOLD}
# sorta analagous to actual notes (B, C, C#, etc)
enum NOTES {A, B, C, D, E}

# hit window stuff (in seconds)
var view_window : float = 1 # from now to now + view window, thats the notes that will show

enum HIT_RESULTS {NO_HIT, HIT, PERFECT}

# note management
@export var note_array : Array
var beats_per_second : float 

# actual beat map
var beatmap_file_path : String = "res://test_map.json"

# score management:
var score : int

# visual stuff
# ---------------
# don't check at just beat, because each beat is a measure, you want subdivisions
# but every beat/measure want to draw a line or just make it easier to organize on screen
# mostly visual, not that important, just juice/polish
@export var beats_per_minute : int = 112 

var note_sprite

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
	note_sprite = load("res://note.tscn")
	
	$HitZone.position.y = GameManager.hit_zone_left_offset
	
	load_beatmap()
	
#	note_array.append(Note.new(NOTES.A, 1.25))
#	note_array.append(Note.new(NOTES.B, 1.5))
#	note_array.append(Note.new(NOTES.C, 1.75))
#	note_array.append(Note.new(NOTES.D, 2.0))

func load_beatmap():
	var file = FileAccess.open(beatmap_file_path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	if error == OK:
		var data_received = json.data
		if typeof(data_received) == TYPE_DICTIONARY:
			# actually convert our json data into usable beatmap data
			for note_data in data_received["notes"]:
				# parse each note and convert into actual note object
				var note_name : NOTES
				match note_data["name"]:
					"A": note_name = NOTES.A
					"B": note_name = NOTES.B
					"C": note_name = NOTES.C
					"D": note_name = NOTES.D
					"E": note_name = NOTES.E
				var note_start_time : float = note_data["start_time"]
				note_array.append(Note.new(note_name, note_start_time))
			
			# each member in the note array is a 2-tuple of [NoteObject, NoteSprite]
			note_array = note_array.map(note_spawner)
			
		else:
			print("Unexpected data")
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", content, " at line ", json.get_error_line())

func note_spawner(note_obj):
	# Spawns a note sprite instance for every note object in the map array.
	var new_note = note_sprite.instantiate()
	add_child(new_note)
	
	return [note_obj, new_note]

func calculate_current_song_data():
	# figure out what beat we're on
	beats_per_second = beats_per_minute / 60.0
	
func delete_note(note_pair):
	# Stops a note from being hit twice, removing the visual instance of a note when it is.
	note_pair[0].already_hit = true
	note_pair[1].queue_free()

func hit_note(note_name : NOTES, note_array : Array, current_time : float):
	$DebugNoteLabel.text = str("note name ", note_name)
	
	# go through every single note on screen and see which one is close enough to hit, and wheather it matches the note the player hit
	for note in range(len(note_array)):
		if !note_array[note][0].already_hit:
			if (note_array[note][0].start_time + GameManager.hit_window) < current_time:
				# Handles ignoring notes that were missed.
				# Note this does cause visual behavior that looks like a hit that failed to miss.
				# If you miss the timing window, but haven't fully cleared the left edge, the note will still disappear.
				delete_note(note_array[note])
				
			elif note_array[note][0].note_name == note_name:
				var hit_result = note_array[note][0].check_hit(current_time)
				if hit_result != HIT_RESULTS.NO_HIT:
					if hit_result == HIT_RESULTS.PERFECT:
						score += 1000
					elif hit_result == HIT_RESULTS.HIT:
						score += 100
					delete_note(note_array[note])
					
					$Score.text = str(score)
					
					note_array.remove_at(note)
					
				return


const note_time : int = 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	time_elapsed_since_start += delta
	
	calculate_current_song_data()
	
	if Input.is_action_just_pressed("note1"):
		print("note1")
		# we want to calculate the time missed by to make the note perfect
		# we want to center the note in the middle of the beat
		hit_note(NOTES.A, note_array, time_elapsed_since_start)
	if Input.is_action_just_pressed("note2"):
		print("note2")
		hit_note(NOTES.B, note_array, time_elapsed_since_start)
	if Input.is_action_just_pressed("note3"):
		print("note3")
		hit_note(NOTES.C, note_array, time_elapsed_since_start)
	if Input.is_action_just_pressed("note4"):
		print("note4")
		hit_note(NOTES.D, note_array, time_elapsed_since_start)
	
	# visual stuff
	
	# move the notes across the screen one by one
	for note in note_array:
		# note is a 2-tuple of [NoteObject, NoteSprite]
		if !note[0].already_hit and note[0].start_time - view_window <= time_elapsed_since_start:
			# display the note position on screen based on the ratio between where the note is spawned and where its supposed to be hit
			# if its 0, its all the way to the right, and visa versa
			var screen_position_ratio : float = (-(note[0].start_time - view_window - time_elapsed_since_start)/view_window)
			note[1].position.x = get_viewport_rect().size.x - screen_position_ratio * get_viewport_rect().size.x + GameManager.hit_zone_left_offset
