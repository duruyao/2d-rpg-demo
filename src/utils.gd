extends Node

func vector_to_lrud(v: Vector2) -> Vector2:
	var left_dot       := v.dot(Vector2.LEFT)
	var right_dot      := v.dot(Vector2.RIGHT)
	var up_dot         := v.dot(Vector2.UP)
	var down_dot       := v.dot(Vector2.DOWN)
	var max_dot: float =  max(left_dot, right_dot, up_dot, down_dot)

	return {
		left_dot: Vector2.LEFT,
		right_dot: Vector2.RIGHT,
		up_dot: Vector2.UP,
		down_dot: Vector2.DOWN
	}[max_dot]
