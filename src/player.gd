extends CharacterBody2D

enum State {
	IDLE,
	MOVE,
	ATTACK,
	DEATH,
}
const INPUT_ACTION_MOVE_LEFT     := "move_left"
const INPUT_ACTION_MOVE_RIGHT    := "move_right"
const INPUT_ACTION_MOVE_UP       := "move_up"
const INPUT_ACTION_MOVE_DOWN     := "move_down"
const INPUT_ACTION_RUN           := "run"
const INPUT_ACTION_ATTACK        := "attack"
const ANIMATION_DIRECTION_FRONT  := "front_"
const ANIMATION_DIRECTION_BACK   := "back_"
const ANIMATION_DIRECTION_SIDE   := "side_"
const ANIMATION_STATE_IDLE       := "idle"
const ANIMATION_STATE_MOVE       := "move"
const ANIMATION_STATE_ATTACK     := "attack"
const ANIMATION_STATE_DEATH      := "death"
const _WALK_SPEED                := 60.0
const _RUN_SPEED                 := 160.0
const _MAX_HP                    := 100.0
const _ATTACK_DAMAGE             := 20.0
const _ATTACK_COOLDOWN_DURATION  := 1.0
const _ATTACK_ANIMATION_DURATION := 1.0
const _ATTACK_DELAY              := 0.3
const _DEATH_ANIMATION_DURATION  := 1.0
const _RELIVE_COOLDOWN_DURATION  := 5.0
const _INVINCIBILITY_DURATION    := 1.5
var _hp                          := _MAX_HP
var _direction                   := Vector2.DOWN
var _can_attack                  := true
var _should_attack               := false
var _is_attacking                := false
var _is_dying                    := false
var _is_invincible               := false
var _enemy: Node2D               =  null
var _field_camera: Camera2D      =  null
var _canyon_camera: Camera2D     =  null


func _ready() -> void:
	$HealthBar.visible = false
	_field_camera = $FieldCamera
	_canyon_camera = $CanyonCamera
	change_camera(Global.FIELD_SCENE)
	$AnimatedSprite2D.play(ANIMATION_DIRECTION_FRONT + ANIMATION_STATE_IDLE)


func _physics_process(_delta: float) -> void:
	_get_input()
	if not is_alive():
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
	if body.is_in_group(Global.ENEMY_GROUP):
		_enemy = body


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group(Global.ENEMY_GROUP):
		_enemy = null


func hp() -> float:
	return _hp


func is_alive()-> bool:
	return _hp > 0.0


func take_damage(damage: float) -> void:
	if not _is_invincible:
		_hp = min(_hp, _hp - damage)
	_update_health_bar()


func change_camera(scene_name: String) -> void:
	_field_camera.enabled = Global.FIELD_SCENE == scene_name
	_canyon_camera.enabled = Global.CANYON_SCENE == scene_name


func _set_later(property: StringName, value: Variant, delay: float = 0.0, object: Object = self) -> void:
	await get_tree().create_timer(delay).timeout
	if object and object.has_method("set"):
		object.set(property, value)


func _call_later(method: StringName, args: Array = [], delay: float = 0.0, object: Object = self) -> void:
	await get_tree().create_timer(delay).timeout
	if object and object.has_method("callv") and object.has_method(method):
		object.callv(method, args)


func _get_input() -> void:
	var input_dir := Input.get_vector(INPUT_ACTION_MOVE_LEFT, INPUT_ACTION_MOVE_RIGHT, INPUT_ACTION_MOVE_UP, INPUT_ACTION_MOVE_DOWN)
	if input_dir.length() > 0:
		_direction = input_dir
	var speed := _WALK_SPEED
	if Input.is_action_pressed(INPUT_ACTION_RUN):
		speed = _RUN_SPEED
	velocity = input_dir * speed * int(is_alive())
	_should_attack = Input.is_action_just_pressed(INPUT_ACTION_ATTACK)


func _play_animation(state: State) -> void:
	if State.DEATH == state:
		$AnimatedSprite2D.play(ANIMATION_STATE_DEATH)
		return
	var anim_name := ""
	var anim_dir  := Utils.vector_to_lrud(_direction)
	anim_name +=  {
		Vector2.LEFT: ANIMATION_DIRECTION_SIDE,
		Vector2.RIGHT: ANIMATION_DIRECTION_SIDE,
		Vector2.UP: ANIMATION_DIRECTION_BACK,
		Vector2.DOWN: ANIMATION_DIRECTION_FRONT,
	}[anim_dir]
	anim_name += {
		State.IDLE: ANIMATION_STATE_IDLE,
		State.MOVE: ANIMATION_STATE_MOVE,
		State.ATTACK: ANIMATION_STATE_ATTACK,
		State.DEATH: ANIMATION_STATE_DEATH,
	}[state]
	$AnimatedSprite2D.flip_h = Vector2.LEFT == anim_dir
	$AnimatedSprite2D.play(anim_name)


func _attack_enemy() -> void:
	# TODO: support attacking multiple enemies
	if _enemy and _can_attack and _enemy.has_method("take_damage"):
		if _direction.dot(_enemy.position - position) > 0:
			print_debug("%s's HP: %.0f - %.0f =" % [_enemy.name, _enemy.hp(), _ATTACK_DAMAGE])
			_call_later("take_damage", [_ATTACK_DAMAGE], _ATTACK_DELAY, _enemy)
	_can_attack = false
	_is_attacking = true
	_set_later( "_can_attack", true, _ATTACK_COOLDOWN_DURATION)
	_set_later( "_is_attacking", false, _ATTACK_ANIMATION_DURATION)


func _update_health_bar() -> void:
	var bar := $HealthBar
	bar.visible = _hp < _MAX_HP
	bar.value = _hp * 100.0 / _MAX_HP


func _relive() -> void:
	_hp = _MAX_HP
	_is_dying = false
	_update_health_bar()
	_is_invincible = true
	_set_later("_is_invincible", false, _INVINCIBILITY_DURATION)


func _die() -> void:
	_is_dying = true
	_call_later("_relive", [], _DEATH_ANIMATION_DURATION + _RELIVE_COOLDOWN_DURATION)
