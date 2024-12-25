extends Node

func vector2_to_lrud(v: Vector2) -> Vector2:
	var left_dot       := v.dot(Vector2.LEFT)
	var right_dot      := v.dot(Vector2.RIGHT)
	var up_dot         := v.dot(Vector2.UP)
	var down_dot       := v.dot(Vector2.DOWN)
	var max_dot: float =  max(left_dot, right_dot, up_dot, down_dot)

	if left_dot == max_dot:
		return Vector2.LEFT
	elif right_dot == max_dot:
		return Vector2.RIGHT
	elif up_dot == max_dot:
		return Vector2.UP
	else:
		return Vector2.DOWN
