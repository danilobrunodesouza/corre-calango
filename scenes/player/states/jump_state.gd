extends "res://scenes/player/states/state.gd"

var player: CharacterBody2D
var _jump_timer: float = 0.0
const MIN_JUMP_TIME: float = 0.10 # Previne transição prematura antes de sair do solo

func enter(_msg: Dictionary = {}) -> void:
	_get_player()
	_jump_timer = 0.0
	if player:
		if player.get("sprite"):
			player.get("sprite").play("jump")
		if player.has_method("jump"):
			player.jump()

func _get_player() -> void:
	if player == null:
		player = get_parent().get_parent() as CharacterBody2D

func physics_update(delta: float) -> void:
	_jump_timer += delta
	_get_player()
	if player and _jump_timer >= MIN_JUMP_TIME and player.velocity.y >= 0.0 and player.is_on_floor():
		state_machine.transition_to("Run")
