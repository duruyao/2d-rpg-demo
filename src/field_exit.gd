extends Area2D

signal exit_entered(scene_name: String, player_position: Vector2)

var _next_scene_name := {
							"East": "Canyon",
							"South": "Canyon",
							"West": "Canyon",
							"North": "Canyon"
						}

var _next_player_position := {
								 "East": Vector2(8, 128),
								 "South": Vector2(238, 15),
								 "West": Vector2(505, 145),
								 "North": Vector2(255, 280)
							 }


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		exit_entered.emit(_next_scene_name[name], _next_player_position[name])


func physics_global_position() -> Vector2:
	return $CollisionShape2D.global_position
