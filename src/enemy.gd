extends CharacterBody2D

enum AnimationState {
	IDLE,
	MOVE,
	ATTACK,
	DEATH,
}
enum AudioState {
	IDLE,
	MOVE,
	ATTACK,
	DEATH,
}
const INPUT_ACTION_ATTACK        := "attack"
const ANIMATION_DIRECTION_FRONT  := "front_"
const ANIMATION_DIRECTION_BACK   := "back_"
const ANIMATION_DIRECTION_SIDE   := "side_"
const ANIMATION_STATE_IDLE       := "idle"
const ANIMATION_STATE_MOVE       := "move"
const ANIMATION_STATE_ATTACK     := "attack"
const ANIMATION_STATE_DEATH      := "death"
const _ATTACK_COOLDOWN_DURATION  := 3.0
const _ATTACK_ANIMATION_DURATION := 1.5
const _ATTACK_DELAY              := 1.2
const _DEATH_ANIMATION_DURATION  := 1.0
const _FREEZE_DURATION           := 2.0
@export var _max_hp := 150.0
@export var _move_speed := 40.0
@export var _attack_damage := 10.0

var _hp                                := 0.0
var _direction                         := Vector2.DOWN
var _can_attack                        := true
var _is_attacking                      := false
var _is_dying                          := false
var _is_near_entrance                  := false
var _is_freezing                       := false
var _targets                           := {}
var _players                           := {}
var _entrance: Area2D                  =  null
var _audio_player: AudioStreamPlayer2D =  null


func _ready() -> void:
	_hp = _max_hp
	$HealthBar.visible = false
	$AnimatedSprite2D.play(ANIMATION_DIRECTION_FRONT + ANIMATION_STATE_IDLE)


func _physics_process(_delta: float) -> void:
	_get_target()
	if not is_alive():
		if not _is_dying:
			_play_animation(AnimationState.DEATH)
			_play_audio(AudioState.DEATH)
			_die()
	elif _can_attack and not _no_alive_player_in_hitbox() and not _is_attacking:
		_play_animation(AnimationState.ATTACK)
		_play_audio(AudioState.ATTACK)
		_try_attack_players()
	elif velocity.length() != 0 and not _is_attacking:
		_play_animation(AnimationState.MOVE)
		_play_audio(AudioState.MOVE)
	elif not _is_attacking:
		_play_animation(AnimationState.IDLE)
		_play_audio(AudioState.IDLE)
	move_and_slide()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group(Global.PLAYER_GROUP):
		_targets[body] = {}


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group(Global.PLAYER_GROUP):
		_targets.erase(body)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group(Global.PLAYER_GROUP):
		_players[body] = {}


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group(Global.PLAYER_GROUP):
		_players.erase(body)


func _on_detection_area_area_entered(area: Area2D) -> void:
	if area.is_in_group(Global.EXIT_GROUP):
		_entrance = area
		_is_near_entrance = true


func _on_detection_area_area_exited(area: Area2D) -> void:
	if area.is_in_group(Global.EXIT_GROUP):
		_entrance = null
		_is_near_entrance = false


func hp() -> float:
	return _hp


func is_alive()-> bool:
	return _hp > 0.0


func take_damage(damage: float) -> void:
	_hp = min(_hp, _hp - damage)
	_update_health_bar()


func _set_later(property: StringName, value: Variant, delay: float = 0.0, object: Object = self) -> void:
	await get_tree().create_timer(delay).timeout
	if object and object.has_method("set"):
		object.set(property, value)


func _call_later(method: StringName, args: Array = [], delay: float = 0.0, object: Object = self) -> void:
	await get_tree().create_timer(delay).timeout
	if object and object.has_method("callv") and object.has_method(method):
		object.callv(method, args)


func _get_target() -> void:
	velocity = Vector2.ZERO
	if _is_near_entrance and _entrance:
		if not _is_freezing: # NOTE: _entrance.global_position is (0, 0)
			_direction = (_entrance.physics_global_position() - global_position).normalized()
			velocity = -1 * _direction * _move_speed * int(is_alive())
			_is_freezing = true
			_set_later("_is_freezing", false, _FREEZE_DURATION)
	elif _no_alive_player_in_hitbox() and not _targets.is_empty():
		for target in _targets.keys():
			if target and target.is_alive():
				_direction = (target.global_position - global_position).normalized()
				velocity = _direction * _move_speed * int(is_alive())
				break


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
		AudioState.MOVE: $MoveSoundPlayer,
		AudioState.ATTACK: $AttackSoundPlayer,
		AudioState.DEATH: $DeathSoundPlayer,
	}[state]
	if next_audio_player != _audio_player or AudioState.ATTACK == state:
		if _audio_player and _audio_player.is_playing():
			_audio_player.stop()
			_audio_player = null
		if next_audio_player:
			_audio_player = next_audio_player
			if AudioState.ATTACK == state:
				await get_tree().create_timer(_ATTACK_DELAY).timeout
			_audio_player.play()


func _attack_player(player: Node2D) -> void:
	if player and _players.has(player):
		player.take_damage(_attack_damage)


func _try_attack_players() -> void:
	# support attacking multiple players
	for player in _players.keys():
		_call_later("_attack_player", [player], _ATTACK_DELAY)
	_can_attack = false
	_is_attacking = true
	_set_later( "_can_attack", true, _ATTACK_COOLDOWN_DURATION)
	_set_later( "_is_attacking", false, _ATTACK_ANIMATION_DURATION)


func _update_health_bar() -> void:
	var bar := $HealthBar
	bar.size.x = 2.0 * _max_hp
	bar.visible = _hp < _max_hp
	bar.value = _hp * 100.0 / _max_hp


func _die() -> void:
	_is_dying = true
	_call_later("queue_free", [], _DEATH_ANIMATION_DURATION)


func _no_alive_player_in_hitbox() -> bool:
	for player in _players.keys():
		if player and player.is_alive():
			return false
	return true
