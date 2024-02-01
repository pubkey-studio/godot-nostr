extends Node

class_name NostrSubHelpers

static func subscribe(relay: NostrRelay, key: String, url: String, filters: Dictionary) -> String:
	print("NostrSubHelpers: subscribe(", relay, ", ", key, ", ", url, ", ", filters, ")")
	relay.subscribe(key, filters)
	return key
