## ObjectPool — reutiliza instâncias de nós para evitar GC spikes.
class_name ObjectPool
extends Node

@export var pooled_scene: PackedScene
var factory_func: Callable
@export var initial_size: int = 5
@export var can_grow: bool = true

var _available: Array[Node] = []
var _in_use: Array[Node] = []

func _ready() -> void:
	if pooled_scene or factory_func.is_valid():
		_initialize_pool()

func init_pool(factory: Callable, count: int = 5) -> void:
	factory_func = factory
	initial_size = count
	_initialize_pool()

func _initialize_pool() -> void:
	for i in initial_size:
		_create_instance()

func _create_instance() -> Node:
	var instance: Node = null
	if pooled_scene:
		instance = pooled_scene.instantiate()
	elif factory_func.is_valid():
		instance = factory_func.call()

	if instance == null:
		push_error("ObjectPool: falha ao criar instância!")
		return null

	instance.process_mode = Node.PROCESS_MODE_DISABLED
	if instance is CanvasItem:
		instance.visible = false
	add_child(instance)
	_available.append(instance)

	if instance.has_signal("returned_to_pool"):
		instance.connect("returned_to_pool", Callable(self, "_return_to_pool").bind(instance))

	return instance

func get_instance() -> Node:
	var instance: Node

	if _available.is_empty():
		if can_grow:
			instance = _create_instance()
			_available.erase(instance)
		else:
			push_warning("ObjectPool exhausted and cannot grow")
			return null
	else:
		instance = _available.pop_back()

	if instance == null:
		return null

	instance.process_mode = Node.PROCESS_MODE_INHERIT
	if instance is CanvasItem:
		instance.visible = true
	_in_use.append(instance)

	if instance.has_method("on_spawn"):
		instance.on_spawn()

	return instance

func _return_to_pool(instance: Node) -> void:
	if not instance in _in_use:
		return

	_in_use.erase(instance)

	if instance.has_method("on_despawn"):
		instance.on_despawn()

	instance.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	if instance is CanvasItem:
		instance.set_deferred("visible", false)
	_available.append(instance)

func return_all() -> void:
	for instance in _in_use.duplicate():
		_return_to_pool(instance)
