extends Node

class_name NostrNote 

var note: Dictionary = {}

func _init( event: Dictionary = { "created_at": 0, "sig": "", "id": "", "pubkey": "", "content": "", "tags": [] } ):
	note = event

func gimme( key: String ):
	if note.has(key):
		return note[key]
	
func find_tags( key: String ) -> Array: 
	if not note.has("tags"):
		return []
	var tags: Array = []
	for tag in note.tags:
		if tag[0] == key:
			tags.append(tag)
	return tags 

func from_tag_key_get_indices( key: String, indices: Array = [1] ) -> Array:
	print("NostrNote: from_tag_key_get_indices(", key, ", ", indices, ")")
	return from_tag_keys_get_indices([key], indices)

func from_tag_keys_get_indices( keys: Array, indices: Array = [1] ) -> Array:
	print("NostrNote: from_tag_keys_get_indices(", keys, ", ", indices, ")")
	var tags: Array = []
	
	for key in keys:
		tags = tags + find_tags( key )
		
	#print('tags: ', tags)

	var results: Array = []
	for tag in tags:
		#print("NostrNote: tag in tags: ", tag)
		var tag_res: Array = []
		for index in indices: 
			#print("NostrNote: does tag[", index, "] exist?", tag, " ", tag.has(index))
			if index >= 0 and index < tag.size():
				tag_res.append(tag[index])	
		if(tag_res.size() > 0):
			results.append(tag_res)
	return results
	
func flatten_array(input_array: Array) -> Array:
	var flattened_array = []

	for item in input_array:
		if item is Array:
			flattened_array += flatten_array(item)
		else:
			flattened_array.append(item)

	return flattened_array 
	
func topics(): 
	return flatten_array( from_tag_key_get_indices( 't' ) )
	
func pre_id():
	return flatten_array( from_tag_key_get_indices( 'd' ) )
	
func geo( includes: Array = [], include_classifiers: bool = false ):
	var keys = ['g']
	if(include_classifiers):
		keys.append('G')
	var tags = from_tag_keys_get_indices( keys, [1,2] )
	if includes.size() == 0:
		return tags
		
	var filtered: Array = []
	for tag in tags:
		if tag.size() == 2 && 'geohash' in includes:
			filtered.append(tag) 
			continue
		if tag[0] == 'g':
			if tag[2] in includes:
				filtered.append(tag)
		elif tag[0] == 'G':
			if tag[1] in includes:
				filtered.append(tag)		
	return filtered

func labels( includes: Array = [], include_classifiers: bool = false ):
	var keys = ['l']
	if(include_classifiers):
		keys.append('L')
	var tags = from_tag_keys_get_indices( keys, [1,2] )
	if includes.size() == 0:
		return tags
		
	var filtered: Array = []
	for tag in tags:
		if tag[0] == 'l':
			if tag[2] in includes:
				filtered.append(tag)
		elif tag[0] == 'L':
			if tag[1] in includes:
				filtered.append(tag)	
	return filtered
