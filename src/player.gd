extends CharacterBody2D

const DEFAULT_SPEED     := 60.0
const MAX_SPEED         := 160.0
const ACCELERATED_SPEED := 50.0
var current_speed       := DEFAULT_SPEED
var current_dir         := Vector2.DOWN


func get_input(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length() > 0:
		current_dir = input_dir
	if Input.is_action_pressed("run"):
		current_speed = min(current_speed + ACCELERATED_SPEED * delta, MAX_SPEED)
	elif current_speed > DEFAULT_SPEED:
		current_speed = max(current_speed - ACCELERATED_SPEED * delta, DEFAULT_SPEED)
	else:
		current_speed = DEFAULT_SPEED
	velocity = input_dir * current_speed


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


func _physics_process(delta: float) -> void:
	get_input(delta)
	play_animation()
	move_and_slide()
