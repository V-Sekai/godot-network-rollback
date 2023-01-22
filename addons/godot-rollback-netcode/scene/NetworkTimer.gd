extends Node
class_name NetworkTimer

@export var autostart: bool = false
@export var one_shot: bool = false
@export var wait_ticks: int = 0
@export var hash_state: bool = true

var ticks_left := 0

var _running := false

signal timeout


func _ready() -> void:
	add_to_group("network_sync")
	SyncManager.connect("sync_stopped", Callable(self, "_on_SyncManager_sync_stopped"))
	if autostart:
		start()


func is_stopped() -> bool:
	return not _running


func start(ticks: int = -1) -> void:
	if ticks > 0:
		wait_ticks = ticks
	ticks_left = wait_ticks
	_running = true


func stop():
	_running = false
	ticks_left = 0


func _on_SyncManager_sync_stopped() -> void:
	stop()


func _network_process(_input: Dictionary) -> void:
	if not _running:
		return
	if ticks_left <= 0:
		_running = false
		return

	ticks_left -= 1

	if ticks_left == 0:
		if not one_shot:
			ticks_left = wait_ticks
		emit_signal("timeout")


func _save_state() -> Dictionary:
	if hash_state:
		return {
			running = _running,
			wait_ticks = wait_ticks,
			ticks_left = ticks_left,
		}
	else:
		return {
			_running = _running,
			_wait_ticks = wait_ticks,
			_ticks_left = ticks_left,
		}


func _load_state(state: Dictionary) -> void:
	if hash_state:
		_running = state["running"]
		wait_ticks = state["wait_ticks"]
		ticks_left = state["ticks_left"]
	else:
		_running = state["_running"]
		wait_ticks = state["_wait_ticks"]
		ticks_left = state["_ticks_left"]