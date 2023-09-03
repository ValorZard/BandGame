extends Node

var current_scene = null

var beatmap_player_path : StringName = "res://src/game_engine/beatmap.tscn"
var beatmap_editor_path : StringName = "res://src/mapping_engine/beatmap_maker.tscn"

# whenever we change scenes, update the current_scene variable
func update_current_scene():
	var root = get_tree().root
	# Both the current scene and the autoloaded scenes are children of root, but autoloaded nodes are always first. 
	# This means that the last child of root is always the loaded scene.
	current_scene = root.get_child(root.get_child_count() - 1)

func _ready():
	update_current_scene()


func goto_scene(path : StringName):
	# This function will usually be called from a signal callback,
	# or some other function in the current scene.
	# Deleting the current scene at this point is
	# a bad idea, because it may still be executing code.
	# This will result in a crash or unexpected behavior.

	# The solution is to defer the load to a later time, when
	# we can be sure that no code from the current scene is running:
	update_current_scene()
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path : StringName):
	# It is now safe to remove the current scene
	current_scene.free()

	# Load the new scene.
	var s = ResourceLoader.load(path)

	# Instance the new scene.
	current_scene = s.instantiate()

	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene

# variation for goto scene for packed scenes
func goto_packed_scene(scene_to_change_to : PackedScene):
	update_current_scene()
	call_deferred("_deferred_goto_packed_scene", scene_to_change_to)


func _deferred_goto_packed_scene(scene_to_change_to : PackedScene):
	# It is now safe to remove the current scene
	current_scene.free()

	# Instance the new scene.
	current_scene = scene_to_change_to.instantiate()

	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene


# doing setup for the rhythm game sections
func goto_song(beatmap_file_path : StringName, scene_to_switch_to_after : PackedScene):
	update_current_scene()
	call_deferred("_deferred_goto_song", beatmap_file_path, scene_to_switch_to_after)


func _deferred_goto_song(beatmap_file_path : StringName, scene_to_switch_to_after : PackedScene):
	# It is now safe to remove the current scene
	current_scene.free()

	# Load the new scene.
	var beatmap_player = ResourceLoader.load(beatmap_player_path)

	# Instance the new scene.
	var beatmap_player_instance = beatmap_player.instantiate()
	
	# add all the stuff we need for beatmap_player_instance to function
	if(beatmap_player_instance is BeatmapPlayer):
		beatmap_player_instance.beatmap_file_path = beatmap_file_path
		# make sure the game knows what cutscene to load in after the song is done
		beatmap_player_instance.scene_to_change_to = scene_to_switch_to_after

	# now that setup is done, change scenes to song
	current_scene = beatmap_player_instance
	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene

# this should only get called for the song editor
func goto_edited_song(beatmap_file_path : StringName):
	update_current_scene()
	call_deferred("_deferred_goto_edited_song", beatmap_file_path)


func _deferred_goto_edited_song(beatmap_file_path : StringName):
	# It is now safe to remove the current scene
	current_scene.free()

	# Load the new scene.
	var beatmap_player = ResourceLoader.load(beatmap_player_path)

	# Instance the new scene.
	var beatmap_player_instance = beatmap_player.instantiate()
	
	# add all the stuff we need for beatmap_player_instance to function
	if(beatmap_player_instance is BeatmapPlayer):
		beatmap_player_instance.beatmap_file_path = beatmap_file_path
		beatmap_player_instance.is_being_edited = true

	current_scene = beatmap_player_instance
	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene

# doing setup for the rhythm game sections
func goto_editor(beatmap_file_path : StringName):
	update_current_scene()
	call_deferred("_deferred_goto_editor", beatmap_file_path)


func _deferred_goto_editor(beatmap_file_path : StringName):
	# It is now safe to remove the current scene
	current_scene.free()

	# Load the new scene.
	var beatmap_editor = ResourceLoader.load(beatmap_editor_path)

	# Instance the new scene.
	var beatmap_editor_instance = beatmap_editor.instantiate()
	
	# add all the stuff we need for beatmap_player_instance to function
	if(beatmap_editor_instance is BeatmapMaker):
		beatmap_editor_instance.beatmap_file_path = beatmap_file_path

	# now that setup is done, change scenes to song
	current_scene = beatmap_editor_instance
	# Add it to the active scene, as child of root.
	get_tree().root.add_child(current_scene)

	# Optionally, to make it compatible with the SceneTree.change_scene_to_file() API.
	get_tree().current_scene = current_scene
