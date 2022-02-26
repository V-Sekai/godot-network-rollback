extends Node

const DummyNetworkAdaptor = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")

const GAME_PORT_SETTING = 'network/rollback/log_inspector/replay_port'
const MATCH_SCENE_PATH_SETTING = 'network/rollback/log_inspector/replay_match_scene_path'
const MATCH_SCENE_METHOD_SETTING = 'network/rollback/log_inspector/replay_match_scene_method'

var active := false
var connection: StreamPeerTCP

var match_scene_path: String
var match_scene_method: String = 'setup_match_for_replay'

var _setting_up_match := false

func _ready() -> void:
	if "replay" in OS.get_cmdline_args():
		if not ProjectSettings.has_setting(MATCH_SCENE_PATH_SETTING):
			_show_error_and_quit("Match scene not configured for replay")
			return
		match_scene_path = ProjectSettings.get_setting(MATCH_SCENE_PATH_SETTING)
		
		if ProjectSettings.has_setting(MATCH_SCENE_METHOD_SETTING):
			match_scene_method = ProjectSettings.get_setting(MATCH_SCENE_METHOD_SETTING)
		
		active = true
		
		print ("Connecting to replay server...")
		if not connect_to_replay_server():
			_show_error_and_quit("Unable to connect to replay server")
			return

func _show_error_and_quit(msg: String) -> void:
	OS.alert(msg)
	get_tree().quit(1)

func connect_to_replay_server() -> bool:
	if is_connected_to_replay_server():
		return true
	
	if connection:
		connection.disconnect_from_host()
		connection = null
	
	var port = 49111
	if ProjectSettings.has_setting(GAME_PORT_SETTING):
		port = ProjectSettings.get_setting(GAME_PORT_SETTING)
	
	connection = StreamPeerTCP.new()
	return connection.connect_to_host('127.0.0.1', port) == OK

func is_connected_to_replay_server() -> bool:
	return connection and connection.is_connected_to_host()

func poll() -> void:
	if not active:
		return
	if connection:
		var status = connection.get_status()
		if status == StreamPeerTCP.STATUS_CONNECTED:
			while not _setting_up_match and connection.get_available_bytes() >= 4:
				var length = connection.get_u32()
				var data = connection.get_utf8_string(length)
				
				var result = JSON.parse(data)
				if result.error != OK:
					print ("SyncReplay received invalid JSON: %s" % data)
					continue
				
				process_message(result.result)
		elif status == StreamPeerTCP.STATUS_NONE:
			get_tree().quit()
		elif status == StreamPeerTCP.STATUS_ERROR:
			OS.alert("Error in connection to replay server")
			get_tree().quit(1)

func _process(delta: float) -> void:
	poll()

func process_message(msg: Dictionary) -> void:
	if not msg.has('type'):
		push_error("SyncReplay message has no 'type' property: %s" % msg)
		return
	
	var type = msg['type']
	match type:
		"setup_match":
			var my_peer_id = msg.get('my_peer_id', 1)
			var peer_ids = msg.get('peer_ids', [])
			var match_info = msg.get('match_info', {})
			_do_setup_match1(my_peer_id, peer_ids, match_info)
		
		"load_state":
			var state = msg.get('state', {})
			_do_load_state(state)
			
		_:
			push_error("SyncReplay message has unknown type: %s" % type)

func _do_setup_match1(my_peer_id: int, peer_ids: Array, match_info: Dictionary) -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	
	SyncManager.network_adaptor = DummyNetworkAdaptor.new(my_peer_id)
	SyncManager.mechanized = true
	
	# Abuse WebRTCMultiplayer in order to set our peer id.
	var faux_multiplayer = WebRTCMultiplayer.new()
	faux_multiplayer.initialize(my_peer_id)
	get_tree().set_network_peer(faux_multiplayer)
	
	for peer_id in peer_ids:
		SyncManager.add_peer(peer_id)
	
	if get_tree().change_scene(match_scene_path) != OK:
		_show_error_and_quit("Unable to change scene to: %s" % match_scene_path)
		return
	
	_setting_up_match = true
	call_deferred("_do_setup_match2", my_peer_id, peer_ids, match_info)

func _do_setup_match2(my_peer_id: int, peer_ids: Array, match_info: Dictionary) -> void:
	_setting_up_match = false
	
	var match_scene = get_tree().current_scene
	if not match_scene.has_method(match_scene_method):
		_show_error_and_quit("Match scene has no such method: %s" % match_scene_method)
		return
	
	# Call the scene's setup method.
	match_scene.call(match_scene_method, my_peer_id, peer_ids, match_info)

	SyncManager.start()

func _do_load_state(state: Dictionary) -> void:
	state = SyncManager.hash_serializer.unserialize(state)
	SyncManager._call_load_state(state)
