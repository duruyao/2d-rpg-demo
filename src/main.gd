extends Node

var _field_scene: Node2D     = null
var _canyon_scene: Node2D    = null
var _current_scene: Node2D   = null
var _next_scene: Node2D      = null
var _player: CharacterBody2D = null


func _ready() -> void:
	_field_scene = load("res://src/field.tscn").instantiate()
	_canyon_scene = load("res://src/canyon.tscn").instantiate()
	_current_scene = _field_scene
	_player = _current_scene.get_node("Player")
	add_child(_current_scene)
	for exit in _current_scene.get_node("Exits").get_children():
		exit.exit_entered.connect(_on_exit_player_entered)


func _on_exit_player_entered(scene_name: String, player_position: Vector2) -> void:
	call_deferred("_change_scene", scene_name, player_position)


func _change_scene(scene_name: String, player_position: Vector2) -> void:
	print(scene_name, " ", player_position)
	_next_scene ={
		_field_scene.name: _field_scene,
		_canyon_scene.name: _canyon_scene
	}[scene_name]
	if _current_scene and _next_scene:
		for exit in _current_scene.get_node("Exits").get_children():
			exit.exit_entered.disconnect(_on_exit_player_entered)
		remove_child(_current_scene)
		if _player:
			_player.owner = null
			_current_scene.remove_child(_player)
			_player.position = player_position # NOTE: delayed position updates can cause collision detection
			_player.change_camera(scene_name)
			_next_scene.add_child(_player)
		add_child(_next_scene)
		for exit in _next_scene.get_node("Exits").get_children():
			exit.exit_entered.connect(_on_exit_player_entered)
		_current_scene = _next_scene
		_next_scene = null
