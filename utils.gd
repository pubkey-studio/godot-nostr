extends Object 

class_name NostrUtils

static func generate_uuid_v4():
	var hex_chars = "0123456789ABCDEF"
	var uuid = ""

	for i in range(32):
		var random_char = hex_chars[randi() % 16]
		uuid += random_char

	# Insert dashes at appropriate positions
	uuid = uuid.insert(8, "_")
	uuid = uuid.insert(13, "_")
	uuid = uuid.insert(18, "_")
	uuid = uuid.insert(23, "_")

	return uuid
