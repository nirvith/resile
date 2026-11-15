extends StaticBody2D
# A pinball pad in a corner of the map.
# It is a StaticBody2D on collision layer 1, so to the game it is just a wall:
# bolts, chunks, the blob and enemies all bounce or stop against it.
# What makes a bolt go into pinball mode is in bolt.gd; this script only
# makes the pad look alive: a slow glow pulse, and a white flash when hit.

const BASE_COLOR = Color(0.9, 0.16, 0.67)   # the pad's normal pink
const FLASH_TIME = 0.3                       # seconds a hit flash lasts

var time = 0.0          # seconds since the pad appeared, drives the pulse
var flash_left = 0.0    # seconds of flash remaining

func _ready():
	add_to_group("pinball_pad")

func _process(delta):
	time += delta
	flash_left = max(flash_left - delta, 0.0)
	$Glow.modulate.a = 0.7 + 0.3 * sin(time * 4.0) + flash_left * 3.0
	$Pad.color = BASE_COLOR.lerp(Color.WHITE, flash_left / FLASH_TIME)

func flash():
	flash_left = FLASH_TIME
