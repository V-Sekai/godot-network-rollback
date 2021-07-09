extends Sprite

enum PlayerInputKey {
	INPUT_VECTOR,
}

func _save_state() -> Dictionary:
	return {
		position = position,
	}

func _load_state(state: Dictionary) -> void:
	position = state['position']

func _get_local_input() -> Dictionary:
	var input_vector = Vector2(
		Input.get_action_strength("player_right") - Input.get_action_strength("player_left"),
		Input.get_action_strength("player_down") - Input.get_action_strength("player_up")
	)
	var input := {}
	if input_vector != Vector2.ZERO:
		input[PlayerInputKey.INPUT_VECTOR] = input_vector
	
	return input

func _network_process(delta: float, input: Dictionary) -> void:
	position += input.get(PlayerInputKey.INPUT_VECTOR, Vector2.ZERO) * 4
