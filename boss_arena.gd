extends Node2D
## Rebuild the control deck shell as a stripped-back pinball arena.

func _ready() -> void:
	# Keep its existing floor tiles, walls, and four cover islands. Clear the office props.
	for node_name in ["FloorDecor", "WallDecor", "Furniture", "PinballPads"]:
		var old_props := get_node_or_null(node_name)
		if old_props:
			old_props.hide()
			for collider in old_props.find_children("*", "CollisionObject2D", true, false):
				var collision_object := collider as CollisionObject2D
				if collision_object:
					collision_object.collision_layer = 0
					collision_object.collision_mask = 0
