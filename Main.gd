extends Node2D

onready var connection_panel = $CanvasLayer/ConnectionPanel

const SERVER_PORT = 9999

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")

func _on_ServerButton_pressed() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, 2)
	get_tree().network_peer = peer
	connection_panel.visible = false

func _on_ClientButton_pressed() -> void:
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client('127.0.0.1', SERVER_PORT)
	get_tree().network_peer = peer
	connection_panel.visible = false

func _on_network_peer_connected(peer_id: int):
	$ServerPlayer.set_network_master(1)
	if get_tree().is_network_server():
		$ClientPlayer.set_network_master(peer_id)
	else:
		$ClientPlayer.set_network_master(get_tree().get_network_unique_id())
	
	SyncManager.add_peer(peer_id)
	if get_tree().is_network_server():
		SyncManager.start()
	
	

