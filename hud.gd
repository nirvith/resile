extends CanvasLayer

const CYAN = Color("4fd6e6")
const GOLD = Color("ffc93c")
const EMPTY = Color("2b3a4a")

var player
var waves
var cell_icons = []
var bolt_icons = []

func _ready():
	player = get_tree().get_first_node_in_group("player")
	waves = get_parent().get_node("Waves")
	for i in player.max_cells:
		cell_icons.append(make_icon($Cells, Vector2(18, 16)))
	for i in player.max_bolts:
		bolt_icons.append(make_icon($Bolts, Vector2(14, 14)))

func make_icon(parent, size):
	var icon = ColorRect.new()
	icon.custom_minimum_size = size
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	parent.add_child(icon)
	return icon

func _process(_delta):
	for i in cell_icons.size():
		cell_icons[i].color = CYAN if i < player.cells else EMPTY
	var ready_bolts = player.max_bolts - get_tree().get_nodes_in_group("bolts").size()
	for i in bolt_icons.size():
		bolt_icons[i].color = GOLD if i < ready_bolts else EMPTY
	var lvl = mini(waves.level, waves.levels.size() - 1)
	var total = waves.levels[lvl].waves.size()
	$WaveLabel.text = "LEVEL %d · WAVE %d/%d" % [lvl + 1, mini(waves.current + 1, total), total]
