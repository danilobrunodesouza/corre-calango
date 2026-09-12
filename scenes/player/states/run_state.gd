extends "res://scenes/player/states/state.gd"

var player: CharacterBody2D

func enter(_msg: Dictionary = {}) -> void:
	_get_player()
	if player and player.get("sprite"):
		player.get("sprite").play("run")

func _get_player() -> void:
	if player == null:
		player = get_parent().get_parent() as CharacterBody2D

func physics_update(_delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	_get_player()
	if player == null:
		return

	if Input.is_action_just_pressed("jump") or Input.is_action_pressed("jump"):
		if player.is_on_floor():
			state_machine.transition_to("Jump")
			return
	elif Input.is_action_pressed("duck"):
		state_machine.transition_to("Duck")
		return
