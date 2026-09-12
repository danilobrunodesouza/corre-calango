extends "res://scenes/player/states/state.gd"

var player: CharacterBody2D

func enter(_msg: Dictionary = {}) -> void:
	player = get_parent().get_parent() as CharacterBody2D
	if player:
		if player.get("sprite"):
			player.get("sprite").play("duck")
		if player.has_method("duck_start"):
			player.duck_start()

func exit() -> void:
	if player and player.has_method("duck_end"):
		player.duck_end()

func physics_update(_delta: float) -> void:
	if not Input.is_action_pressed("duck"):
		state_machine.transition_to("Run")
	elif Input.is_action_just_pressed("jump") and player.is_on_floor():
		state_machine.transition_to("Jump")
