extends CharacterBody2D

enum State {
	IDLE,
	MOVE,
	ATTACK,
	DEATH
}
const _WALK_SPEED              := 60.0
const _RUN_SPEED               := 160.0
const _MAX_HP                  := 100.0
var _direction                 := Vector2.DOWN
var _hp                        := _MAX_HP
var _attack_damage             := 20.0
var _enemy: Node2D             =  null
var _can_attack                := true
var _should_attack             := false
var _attack_cooldown_duration  := 1.0
var _is_attacking              := false
var _attack_animation_duration := 1.0
var _is_dying                  := false
var _death_animation_duration  := 1.0
var _field_camera: Camera2D    =  null
var _canyon_camera: Camera2D   =  null
var _relive_cooldown_duration  := 5.0
var _is_invincible             := false
var _invincibility_duration    := 1.5


func _set_later(property: StringName, value: Variant, delay: float = 0.0, object: Object = self) -> void:
	await get_tree().create_timer(delay).timeout
	if object and object.has_method("set"):
		object.set(property, value)


func _call_later(method: StringName, args: Array = [], delay: float = 0.0, object: Object = self) -> void:
	await get_tree().create_timer(delay).timeout
	if object and object.has_method("callv") and object.has_method(method):
		object.callv(method, args)


func _get_input() -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length() > 0:
		_direction = input_dir
	var speed := _WALK_SPEED
	if Input.is_action_pressed("run"):
		speed = _RUN_SPEED
	velocity = input_dir * speed * int(alive())
	_should_attack = Input.is_action_just_pressed("attack")


func _play_animation(state: State) -> void:
	if State.DEATH == state:
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
	$AnimatedSprite2D.flip_h = Vector2.LEFT == anim_dir
	$AnimatedSprite2D.play(anim_name)


func _attack_enemy() -> void:
	# TODO: support attacking multiple enemies
	if _enemy and _can_attack and _enemy.has_method("take_damage"):
		if _direction.dot(_enemy.position - position) > 0:
			print("%s's HP: %.0f - %.0f =" % [_enemy.name, _enemy.hp(), _attack_damage])
			_enemy.take_damage(_attack_damage)
			print("%.0f" % _enemy.hp())
	_can_attack = false
	_is_attacking = true
	_set_later( "_can_attack", true, _attack_cooldown_duration)
	_set_later( "_is_attacking", false, _attack_animation_duration)


func _update_health_bar() -> void:
	var bar := $HealthBar
	bar.visible = _hp < _MAX_HP
	bar.value = _hp * 100.0 / _MAX_HP


func hp() -> float:
	return _hp


func alive()-> bool:
	return _hp > 0.0


func take_damage(damage: float) -> void:
	if not _is_invincible:
		_hp = min(_hp, _hp - damage)
	_update_health_bar()


func _relive() -> void:
	_hp = _MAX_HP
	_is_dying = false
	_update_health_bar()
	_is_invincible = true
	_set_later("_is_invincible", false, _invincibility_duration)


func _die() -> void:
	_is_dying = true
	_call_later("_relive", [], _death_animation_duration + _relive_cooldown_duration)


func change_camera(scene_name: String) -> void:
	_field_camera.enabled = "Field" == scene_name
	_canyon_camera.enabled = "Canyon" == scene_name


func _ready() -> void:
	$HealthBar.visible = false
	_field_camera = $FieldCamera
	_canyon_camera = $CanyonCamera
	change_camera("Field")
	$AnimatedSprite2D.play("front_idle")


func _physics_process(_delta: float) -> void:
	_get_input()
	if not alive():
		if not _is_dying:
			_play_animation(State.DEATH)
			_die()
	elif  _should_attack and _can_attack and not _is_attacking:
		_play_animation(State.ATTACK)
		_attack_enemy()
	elif velocity.length() != 0 and not _is_attacking:
		_play_animation(State.MOVE)
	elif not _is_attacking:
		_play_animation(State.IDLE)
	move_and_slide()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		_enemy = body


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		_enemy = null
