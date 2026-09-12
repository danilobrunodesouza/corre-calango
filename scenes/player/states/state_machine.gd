## StateMachine — gerencia transições entre estados filhos do tipo State.
extends Node

const StateScript = preload("res://scenes/player/states/state.gd")

signal state_changed(from_state: StringName, to_state: StringName)

var current_state: Node
var states: Dictionary = {}

func _ready() -> void:
	init_states()

func init_states() -> void:
	states.clear()
	for child in get_children():
		if child is StateScript:
			states[child.name] = child
			child.state_machine = self
			child.process_mode = Node.PROCESS_MODE_DISABLED

	if states.has("Run"):
		current_state = states["Run"]
	elif not states.is_empty():
		current_state = states.values()[0]

	if current_state:
		current_state.process_mode = Node.PROCESS_MODE_INHERIT
		current_state.enter()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func transition_to(state_name: StringName, msg: Dictionary = {}) -> void:
	if not states.has(state_name):
		push_error("State '%s' not found" % state_name)
		return
	var previous_state: Node = current_state
	if previous_state:
		previous_state.exit()
		previous_state.process_mode = Node.PROCESS_MODE_DISABLED
	current_state = states[state_name]
	current_state.process_mode = Node.PROCESS_MODE_INHERIT
	current_state.enter(msg)
	if previous_state:
		state_changed.emit(previous_state.name, current_state.name)
