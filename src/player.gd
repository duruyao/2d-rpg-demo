extends CharacterBody2D

enum AnimationState {
	IDLE,
	MOVE,
	ATTACK,
	DEATH,
}
enum AudioState {
	IDLE,
	WALK,
	RUN,
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
const _ATTACK_COOLDOWN_DURATION  := 1.0
const _ATTACK_ANIMATION_DURATION := 1.0
const _ATTACK_DELAY              := 0.3
const _DEATH_ANIMATION_DURATION  := 1.0
const _RELIVE_COOLDOWN_DURATION  := 5.0
const _INVINCIBILITY_DURATION    := 1.5
@export var _walk_speed := 60.0
@export var _run_speed := 160.0
@export var _max_hp := 100.0
@export var _attack_damage := 20.0

var _hp                                := 0.0
var _direction                         := Vector2.DOWN
var _should_run                        := false
var _can_attack                        := true
var _should_attack                     := false
var _is_attacking                      := false
var _is_dying                          := false
var _is_invincible                     := false
var _enemies                           := {}
var _field_camera: Camera2D            =  null
var _canyon_camera: Camera2D           =  null
var _audio_player: AudioStreamPlayer2D =  null


func _ready() -> void:
	_hp = _max_hp
	$HealthBar.visible = false
	_field_camera = $FieldCamera
	_canyon_camera = $CanyonCamera
	change_camera(Global.FIELD_SCENE)
	$AnimatedSprite2D.play(ANIMATION_DIRECTION_FRONT + ANIMATION_STATE_IDLE)


func _physics_process(_delta: float) -> void:
	_get_input()
	if not is_alive():
		if not _is_dying:
			_play_animation(AnimationState.DEATH)
			_play_audio(AudioState.DEATH)
			_die()
	elif  _should_attack and _can_attack and not _is_attacking:
		_play_animation(AnimationState.ATTACK)
		_play_audio(AudioState.ATTACK)
		_try_attack_enemies()
	elif velocity.length() != 0 and not _is_attacking:
		_play_animation(AnimationState.MOVE)
		_play_audio(AudioState.RUN if _should_run else AudioState.WALK)
	elif not _is_attacking:
		_play_animation(AnimationState.IDLE)
		_play_audio(AudioState.IDLE)
	move_and_slide()


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group(Global.ENEMY_GROUP):
		_enemies[body] = {}


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group(Global.ENEMY_GROUP):
		_enemies.erase(body)


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
	if object:
		object.set(property, value)


func _call_later(method: StringName, args: Array = [], delay: float = 0.0, object: Object = self) -> void:
	await get_tree().create_timer(delay).timeout
	if object:
		object.callv(method, args)


func _get_input() -> void:
	var input_dir := Input.get_vector(INPUT_ACTION_MOVE_LEFT, INPUT_ACTION_MOVE_RIGHT, INPUT_ACTION_MOVE_UP, INPUT_ACTION_MOVE_DOWN)
	if input_dir.length() > 0:
		_direction = input_dir
	_should_run = Input.is_action_pressed(INPUT_ACTION_RUN)
	_should_attack = Input.is_action_just_pressed(INPUT_ACTION_ATTACK)
	velocity =  input_dir * (_run_speed if _should_run else _walk_speed) * int(is_alive())


func _play_animation(state: AnimationState) -> void:
	if AnimationState.DEATH == state:
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
		AnimationState.IDLE: ANIMATION_STATE_IDLE,
		AnimationState.MOVE: ANIMATION_STATE_MOVE,
		AnimationState.ATTACK: ANIMATION_STATE_ATTACK,
		AnimationState.DEATH: ANIMATION_STATE_DEATH,
	}[state]
	$AnimatedSprite2D.flip_h = Vector2.LEFT == anim_dir
	$AnimatedSprite2D.play(anim_name)


func _play_audio(state: AudioState) -> void:
	var next_audio_player: AudioStreamPlayer2D = null
	next_audio_player = {
		AudioState.IDLE: null,
		AudioState.WALK: $WalkSoundPlayer,
		AudioState.RUN: $RunSoundPlayer,
		AudioState.ATTACK: $AttackSoundPlayer,
		AudioState.DEATH: $DeathSoundPlayer,
	}[state]
	if next_audio_player != _audio_player or AudioState.ATTACK == state:
		if _audio_player and _audio_player.is_playing():
			_audio_player.stop()
			_audio_player = null
		if next_audio_player:
			_audio_player = next_audio_player
			_audio_player.play()


func _attack_enemy(enemy: Node2D)->void:
	if enemy and _enemies.has(enemy):
		print_debug("%s's HP: %.0f - %.0f =" % [enemy.name, enemy.hp(), _attack_damage])
		enemy.take_damage(_attack_damage)


func _try_attack_enemies() -> void:
	# support attacking multiple enemies
	for enemy in _enemies.keys():
		_call_later("_attack_enemy", [enemy], _ATTACK_DELAY)
	_can_attack = false
	_is_attacking = true
	_set_later( "_can_attack", true, _ATTACK_COOLDOWN_DURATION)
	_set_later( "_is_attacking", false, _ATTACK_ANIMATION_DURATION)


func _update_health_bar() -> void:
	var bar := $HealthBar
	bar.size.x = 2.0 * _max_hp
	bar.visible = _hp < _max_hp
	bar.value = _hp * 100.0 / _max_hp


func _relive() -> void:
	_hp = _max_hp
	_is_dying = false
	_update_health_bar()
	_is_invincible = true
	_set_later("_is_invincible", false, _INVINCIBILITY_DURATION)


func _die() -> void:
	_is_dying = true
	_call_later("_relive", [], _DEATH_ANIMATION_DURATION + _RELIVE_COOLDOWN_DURATION)
