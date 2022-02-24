extends "res://addons/godot-rollback-netcode/NetworkAdaptor.gd"

func send_ping(peer_id: int, msg: Dictionary) -> void:
	pass

func send_ping_back(peer_id: int, msg: Dictionary) -> void:
	pass

func send_remote_start(peer_id: int) -> void:
	pass

func send_remote_stop(peer_id: int) -> void:
	pass

func send_input_tick(peer_id: int, msg: PoolByteArray) -> void:
	pass

func is_network_host() -> bool:
	return true

func is_network_master_for_node(node: Node) -> bool:
	return true

func get_network_master_for_node(node: Node) -> int:
	return 1

func get_network_unique_id() -> int:
	return 1
