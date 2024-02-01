extends Node

class_name NostrEventHelpers

func find_tag_with_index(tag_list: Array, index: String, key: String):
	for tag in tag_list:
		if tag.size() > 1 and tag[1] == index and tag.size() > 2:
			for i in range(tag.size() - 2):
				if tag[i] == key:
					return tag[i + 1]
	return null

# Helper method to retrieve author (pubkey)
func get_author(event: Dictionary):
	return event["pubkey"]

# Helper method to retrieve date (created_at)
func get_date(event: Dictionary):
	return event["created_at"]

func get_content(event: Dictionary):
	return event["content"]

# Helper method to map predefined "tag types" to a predefined response format
func map_tag_type(tag_list: Array, tag_type: String):
	var response = []
	for tag in tag_list:
		if tag.size() > 0 and tag[0] == tag_type:
			response.append(tag)
	return response
