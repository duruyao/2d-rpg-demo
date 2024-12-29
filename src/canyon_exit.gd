extends Area2D

signal exit_entered(scene_name: String, player_position: Vector2)

var _next_scene_name := {
							"East": "Field",
							"South": "Field",
							"West": "Field",
							"North": "Field"
						}

var _next_player_position := {
								 "East": Vector2(25, 50),
								 "South": Vector2(750, 20),
								 "West": Vector2(750, 260),
								 "North": Vector2(675, 425)
							 }


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		exit_entered.emit(_next_scene_name[name], _next_player_position[name])


func physics_global_position() -> Vector2:
	return $CollisionShape2D.global_position
