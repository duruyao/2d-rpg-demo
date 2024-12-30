extends Area2D

signal exit_entered(scene_name: String, player_position: Vector2)

var _next_scene_name := {
							Global.EAST_EXIT_NODE: Global.FIELD_SCENE,
							Global.SOUTH_EXIT_NODE: Global.FIELD_SCENE,
							Global.WEST_EXIT_NODE: Global.FIELD_SCENE,
							Global.NORTH_EXIT_NODE: Global.FIELD_SCENE,
						}

var _next_player_position := {
								 Global.EAST_EXIT_NODE: Vector2(25, 50),
								 Global.SOUTH_EXIT_NODE: Vector2(750, 20),
								 Global.WEST_EXIT_NODE: Vector2(750, 260),
								 Global.NORTH_EXIT_NODE: Vector2(675, 425),
							 }


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(Global.PLAYER_GROUP):
		exit_entered.emit(_next_scene_name[name], _next_player_position[name])


func physics_global_position() -> Vector2:
	return $CollisionShape2D.global_position
