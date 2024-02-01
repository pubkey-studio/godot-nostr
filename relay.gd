extends Node

class_name NostrRelay

var server_url: String
var server_port: int
var emit_each_event: bool
var eose_return_all_events: bool

var events: Dictionary = {}
var event_handlers: Dictionary = {}

var token: String = ''

var ws: WebSocketPeer
var is_connected: bool = false
var message_queue: Array = []

enum MessageType { EVENT, REQ, CLOSE }

signal on_relay_open()
signal on_relay_open_error()
signal on_relay_closed(message: String)

signal on_relay_sub_closed(message: String, subid: String)
signal on_relay_event( key: String, subid: String, content: Variant )
signal on_relay_notice( key: String, message: String)
signal on_relay_eose( key: String, subid: String )
signal on_relay_eose_events( key: String, subid: String, events: Array )
signal on_relay_ok( key: String, event_id: String )
signal on_relay_auth( key: String, challenge: String )

func _init(url: String, port: int = 443, _emit_each_event: bool = false, _eose_return_all_events: bool = true):
	server_url = url
	server_port = port
	emit_each_event = _emit_each_event
	eose_return_all_events = _eose_return_all_events
	token = NostrUtils.generate_uuid_v4()
	# Initialize WebSocketPeer
	ws = WebSocketPeer.new()
	self.connect_to_relay()

func connect_to_relay():
	ws.connect_to_url(server_url)

func get_signal_key( event: String, key: String ) -> String:
	return "on_relay_" + event + ":" + get_keyed_token( key )  

func process_message(message: String):
	var json = JSON.new()
	var error = json.parse(message)

	if error == OK:
		var message_array = json.data
		var key 

		if message_array is Array and message_array.size() >= 2:
			
			if message_array[1] is String and '@' in message_array[1]:
				key = message_array[1].split('@')[0]
				token = message_array[1].split('@')[1]

			match message_array[0]:
				"EVENT":
					print("NostrRelay: process_message(): EVENT")
					if token not in events:
						print("NostRelay: instantiate events array")
						events[ token ] = []	
					if emit_each_event:
						emit_signal( "on_relay_event", get_signal_key("event", key), message_array[1], message_array[2])
					else: 
						events[token].append(message_array[2])
						print("NostrRelay: process_message(): EVENT: events[", token,"].size() = ", events[token].size())
						print(message_array[2])
						
				"NOTICE":
					print("NostrRelay: process_message(): NOTICE")
					emit_signal( "on_relay_notice", get_signal_key("notice", key), message_array[1])
				"CLOSED":
					print("NostrRelay: process_message(): CLOSED")
					emit_signal( "on_relay_sub_closed", get_signal_key("closed", key), message_array[1])
				"OK":
					print("NostrRelay: process_message(): OK")
					emit_signal( "on_relay_ok", get_signal_key("ok", key), message_array[1])
				"AUTH":
					print("NostrRelay: process_message(): AUTH")
					emit_signal( "on_relay_auth", get_signal_key("auth", key), message_array[1])
				"EOSE":
					print("NostrRelay: process_message(): EOSE")
					if eose_return_all_events:
						print("NostrRelay: process_message(): EOSE: return events: ", events[token].size(), ' events')
						emit_signal( "on_relay_eose_events", get_signal_key("eose_events", key), message_array[1], events[token])	
					else:
						print("NostrRelay: process_message(): EOSE: standard result")
						emit_signal( "on_relay_eose", get_signal_key("eose", key), message_array[1], message_array[2])
				_:
					# Unknown message type
					pass
		else:
			# Invalid message format
			pass
	else:
		# Invalid message format
		pass

func on(signal_name, target, method):
	print("NostrRelay:  on(", signal_name, ", ", target, ", ", method, ")")
	var callable = Callable(target, method)
	connect(signal_name, callable)

func send_message(message: Array):
	var json = JSON.new()
	var json_stringified = json.stringify(message)
	print("NostrRelay: send_message(", json_stringified, ")")
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		print("NostrRelay: send_message(): SENT!")
		ws.send_text( json_stringified )
	else:
		message_queue.append({"content": message})

func new_session() -> void:
	print("NostrRelay: new_session()")
	clear_events()
	refresh_token()

func refresh_token() -> void:
	print("NostrRelay: refresh_token() ")
	token = NostrUtils.generate_uuid_v4()
	
func clear_events() -> void:
	events[token] = null

func get_keyed_token(key: String) -> String:
	return key + "@" + token

func publish(event_data: Dictionary):
	send_message([MessageType.EVENT, event_data])

func subscribe(key: String = '', filters: Dictionary = {}):
	var subscription_id = get_keyed_token(key)
	send_message(["REQ", subscription_id, filters])

func close_subscription(subscription_id: String):
	send_message([MessageType.CLOSE, subscription_id])
	
func process(delta: float) -> void:
	ws.poll()
	var state = ws.get_ready_state()
	match state:
		WebSocketPeer.STATE_CONNECTING:
			pass
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_OPEN:
			if not is_connected:
				is_connected = true 
				emit_signal("on_relay_open", self) 
			while ws.get_available_packet_count() > 0:
				var data = ws.get_packet().get_string_from_utf8()
				process_message(data)
			if message_queue.size() > 0:
				for message in message_queue:
					send_message(message.content)
				message_queue.clear()
		WebSocketPeer.STATE_CLOSED, WebSocketPeer.STATE_CLOSING:
			is_connected = false
			emit_signal("on_relay_closed", self) 
			
func _exit_tree():
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		ws.close()
	is_connected = false
