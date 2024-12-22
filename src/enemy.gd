extends CharacterBody2D

const DEFAULT_SPEED := 40.0
var current_dir     := Vector2.DOWN
var target: Node2D  =  null


func get_target() -> void:
	velocity = Vector2.ZERO
	if target:
		current_dir = (target.position - position).normalized()
		velocity = current_dir * DEFAULT_SPEED


func play_animation() -> void:
	var animation      := ""
	var left_dot       := current_dir.dot(Vector2.LEFT)
	var right_dot      := current_dir.dot(Vector2.RIGHT)
	var up_dot         := current_dir.dot(Vector2.UP)
	var down_dot       := current_dir.dot(Vector2.DOWN)
	var max_dot: float =  max(left_dot, right_dot, up_dot, down_dot)

	if left_dot == max_dot:
		animation += "side"
		$AnimatedSprite2D.flip_h = true
	elif right_dot == max_dot:
		animation += "side"
		$AnimatedSprite2D.flip_h = false
	elif up_dot == max_dot:
		animation += "back"
	else:
		animation += "front"

	if velocity.length() > 0:
		animation += "_move"
	else:
		animation += "_idle"
	$AnimatedSprite2D.play(animation)


func _ready() -> void:
	$AnimatedSprite2D.play("front_idle")


func _physics_process(_delta: float) -> void:
	get_target()
	play_animation()
	move_and_slide()


func _on_detection_area_body_entered(body: Node2D) -> void:
	target = body


func _on_detection_area_body_exited(_body: Node2D) -> void:
	target = null

	