extends Node

class_name NostrUser

var Note = preload("res://addons/nostr/note.gd")

var USER_DATA_RELAY

var pubkey
var nip05
var relays 
var profile 
var follows
var token

signal user_data_loaded( user: NostrUser )

func _init(_pubkey: String, _nip05: String = '', user_data_relay: String = 'wss://purplepag.es' ):
	pubkey = _pubkey
	if _nip05 != '':
		nip05 = _nip05 
	USER_DATA_RELAY = user_data_relay
	
func set_user_data(relay: NostrRelay, filters: Dictionary = {}):
	token = relay.token
	var key = get_user_data(relay, filters)
	relay.on( 'on_relay_eose_events', self, "_set_user_data")

func _set_user_data( key: String, subid: String, events: Array ):
	print("NostrUser: _set_user_data()")
	
	if "user_data" not in subid or token not in subid:
		return
		
	for event in events:
		var note = Note.new(event)
		if(event.kind == 0):
			var json = JSON.new()
			var error = json.parse(note.gimme('content'))
			if error == OK:
				profile = json.data
			continue
		if(event.kind == 3):
			follows = note.flatten_array( note.from_tag_key_get_indices( 'p' ) )
			continue
		if(event.kind == 10002):
			relays = note.flatten_array( note.from_tag_key_get_indices( 'r' ) )
			continue
	
	emit_signal("user_data_loaded", self)

func on(signal_name, target, method):
	print("NostrUser:  on(", signal_name, ", ", target, ", ", method, ")")
	var callable = Callable(target, method)
	connect(signal_name, callable)

func get_user_data(relay: NostrRelay, filters: Dictionary = {}) -> String:
	token = relay.token
	print('NostrUser: Getting user data')
	var _filters = { "authors": [pubkey], "kinds": [0,3,10002] }
	var key = 'user_data'
	filters.merge(_filters)

	return NostrSubHelpers.subscribe( relay, key, USER_DATA_RELAY, filters )
	
func get_user_follows(relay: NostrRelay, filters: Dictionary = {}) -> String: 
	token = relay.token
	var _filters = { "authors": [pubkey], "kinds": [3] }
	var key = 'user_follows'
	filters.merge(_filters)
	return NostrSubHelpers.subscribe( relay, key, USER_DATA_RELAY, filters )
	
func get_user_profile(relay: NostrRelay, filters: Dictionary = {}) -> String:
	token = relay.token
	var _filters = { "authors": [pubkey], "kinds": [0] }
	var key = 'user_profile'
	filters.merge(_filters)
	return NostrSubHelpers.subscribe( relay, key, USER_DATA_RELAY, filters )
	
func get_user_relays(relay: NostrRelay, filters: Dictionary = {}) -> String: 
	token = relay.token
	var _filters = { "authors": [pubkey], "kinds": [10002] }
	var key = 'user_relays'
	filters.merge(_filters)
	return NostrSubHelpers.subscribe(relay, key, USER_DATA_RELAY, filters )
	
func get_user_notes(relay: NostrRelay, filters: Dictionary = {}) -> String:
	token = relay.token
	var _filters = { "authors": [pubkey], "kinds": [1] }
	var key = 'user_notes'
	filters.merge(_filters)
	return NostrSubHelpers.subscribe(relay, key, USER_DATA_RELAY, filters )
