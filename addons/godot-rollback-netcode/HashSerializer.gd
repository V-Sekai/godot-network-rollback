extends Reference

func serialize(value):
	if value is Dictionary:
		return serialize_dictionary(value)
	elif value is Array:
		return serialize_array(value)
	elif value is Resource:
		return serialize_resource(value)
	elif value is Object:
		return serialize_object(value)
	return value

func serialize_dictionary(value: Dictionary) -> Dictionary:
	var serialized := {}
	for key in value:
		serialized[key] = serialize(value[key])
	return serialized

func serialize_array(value: Array):
	var serialized := []
	for item in value:
		serialized.append(serialize(item))
	return serialized

func serialize_resource(value: Resource):
	return {
		_ = 'resource',
		path = value.resource_path,
	}

func serialize_object(value: Object):
	return {
		_ = 'object',
		string = value.to_string(),
	}

func unserialize(value):
	if value is Dictionary:
		if not value.has('_'):
			return unserialize_dictionary(value)
		
		if value['_'] == 'resource':
			return unserialize_resource(value)
		
		return unserialize_object(value)
	elif value is Array:
		return unserialize_array(value)
	return value

func unserialize_dictionary(value: Dictionary):
	var unserialized := {}
	for key in value:
		unserialized[key] = unserialize(value[key])
	return unserialized

func unserialize_array(value: Array):
	var unserialized := []
	for item in value:
		unserialized.append(unserialize(item))
	return unserialized

func unserialize_resource(value: Dictionary):
	return load(value['path'])

func unserialize_object(value: Dictionary):
	if value['_'] == 'object':
		return value['string']
	return null
