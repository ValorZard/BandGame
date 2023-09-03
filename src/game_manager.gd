extends Node

# overall hit window
const hit_window : float = 0.10

# hit window when the player hits the notes perfectly
const perfect_hit_window : float = 0.02

# hit zone left-x offset (px)
const hit_zone_left_offset : int = 200

const note_vertical_offset : int = 300

var belh = 0

# Time in seconds to wait before clearing a note that has passed the left edge of the hitzone.
const WAIT_CLEAR : int = 1

# scoring consts
const PERFECT_SCORE = 1000
const NORMAL_SCORE = 100

# data that will change as the game goes on (DO NOT OVERUSE THIS)
