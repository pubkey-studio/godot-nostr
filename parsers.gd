extends Node

class_name NostrParse

static func profile(note: NostrNote) -> Dictionary:
	var json = JSON.new()
	var error = json.parse(note.gimme('content'))
	if error == OK:
		return json.data
	return {}
	
static func follows(note: NostrNote) -> Array:
	return note.flatten_array( note.from_tag_key_get_indices( 'p' ) )

static func relays(note: NostrNote) -> Array:
	return note.flatten_array( note.from_tag_key_get_indices( 'r' ) )
