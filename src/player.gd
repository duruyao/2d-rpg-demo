extends CharacterBody2D

const SPEED     := 100.0
var current_dir := Vector2.DOWN


func get_input() -> void:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir.length() > 0:
		current_dir = input_dir
	velocity = input_dir * SPEED


func play_animation() -> void:
	var animation := ""
	if current_dir.x != 0:
		animation += "side"
	elif current_dir.y < 0:
		animation += "back"
	else:
		animation += "front"
	if velocity.length() > 0:
		animation += "_move"
	else:
		animation += "_idle"
	$AnimatedSprite2D.flip_h = current_dir.x < 0
	$AnimatedSprite2D.play(animation)


func _ready() -> void:
	$AnimatedSprite2D.play("front_idle")


func _physics_process(_delta: float) -> void:
	get_input()
	play_animation()
	move_and_slide()
