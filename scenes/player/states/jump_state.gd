extends "res://scenes/player/states/state.gd"

var player: CharacterBody2D
var _jump_timer: float = 0.0

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
	if player and _jump_timer >= 0.12 and player.velocity.y >= 0.0 and player.is_on_floor():
		state_machine.transition_to("Run")
