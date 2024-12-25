extends CharacterBody2D

enum State {
	IDLE,
	MOVE,
	ATTACK,
	DEATH
}
const _MOVE_SPEED              := 40.0
var _direction                 := Vector2.DOWN
var _hp                        := 150.0
var _attack_damage             := 10.0
var _player: Node2D            =  null
var _can_attack                := true
var _should_attack             := false
var _attack_cooldown_duration  := 3.0
var _is_attacking              := false
var _attack_animation_duration := 1.0
var _is_dying                  := false
var _death_animation_duration  := 1.0


func _set_later(property: StringName, value: Variant, delay: float = 0.0, object: Object = self) -> void:
	await get_tree().create_timer(delay).timeout
	if object and object.has_method("set"):
		object.set(property, value)


func _call_later(method: StringName, args: Array = [], delay: float = 0.0, object: Object = self) -> void:
	await get_tree().create_timer(delay).timeout
	if object and object.has_method("callv") and object.has_method(method):
		object.callv(method, args)


func _get_player() -> void:
	velocity = Vector2.ZERO
	if _player:
		_direction = (_player.position - position).normalized()
		velocity = _direction * _MOVE_SPEED * int(_alive())


func _play_animation(state: State) -> void:
	if state == State.DEATH:
		$AnimatedSprite2D.play("death")
		return
	var anim_name := ""
	var anim_dir  := Utils.vector2_to_lrud(_direction)
	anim_name +=  {
		Vector2.LEFT: "side_",
		Vector2.RIGHT: "side_",
		Vector2.UP: "back_",
		Vector2.DOWN: "front_"
	}[anim_dir]
	anim_name += {
		State.IDLE: "idle",
		State.MOVE: "move",
		State.ATTACK: "attack",
		State.DEATH: "death",
	}[state]
	$AnimatedSprite2D.flip_h = (anim_dir == Vector2.LEFT)
	$AnimatedSprite2D.play(anim_name)


func _attack_player() -> void:
	# TODO: improve enemy lock system
	if _player.has_method("take_damage"):
		print("%s's HP: %.0f - %.0f" % [_player.name, _player.hp(), _attack_damage])
		_player.take_damage(_attack_damage)
	_can_attack = false
	_is_attacking = true
	_set_later( "_can_attack", true, _attack_cooldown_duration)
	_set_later( "_is_attacking", false, _attack_animation_duration)


func hp() -> float:
	return _hp


func take_damage(damage: float) -> void:
	_hp = min(_hp, _hp - damage)


func _alive()-> bool:
	return _hp > 0.0


func _die() -> void:
	_is_dying = true
	_call_later("queue_free", [], _death_animation_duration)


func _ready() -> void:
	$AnimatedSprite2D.play("front_idle")


func _physics_process(_delta: float) -> void:
	_get_player()
	if not _alive():
		if not _is_dying:
			_play_animation(State.DEATH)
			_die()
	elif  _should_attack and _can_attack and not _is_attacking:
		_play_animation(State.ATTACK)
		_attack_player()
	elif velocity.length() != 0 and not _is_attacking:
		_play_animation(State.MOVE)
	elif not _is_attacking:
		_play_animation(State.IDLE)
	move_and_slide()


func _on_detection_area_body_entered(body: Node2D) -> void:
	_player = body


func _on_detection_area_body_exited(_body: Node2D) -> void:
	_player = null


func _on_hitbox_body_entered(_body: Node2D) -> void:
	_should_attack = true


func _on_hitbox_body_exited(_body: Node2D) -> void:
	#	_player = null
	_should_attack = false