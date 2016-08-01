
extends Sprite

var num_images=0

func get(host,port,file,raw=false):
	var http=HTTPClient.new()
	var err=0
	var headers=["User-Agent: Pirulo/1.0 (Godot)","Accept: */*"]
	err = http.connect(host,port) # Connect to host/port
	assert(err==OK) # Make sure connection was OK
	while( http.get_status()==HTTPClient.STATUS_CONNECTING or http.get_status()==HTTPClient.STATUS_RESOLVING):
		http.poll()
		print("Connecting..")
		OS.delay_msec(500)
	assert( http.get_status() == HTTPClient.STATUS_CONNECTED ) # Could not connect
	err = http.request(HTTPClient.METHOD_GET,file,headers) # Request a page from the site (this one was chunked..)
	assert( err == OK ) # Make sure all is OK
	while (http.get_status() == HTTPClient.STATUS_REQUESTING):
		http.poll()
		print("Requesting..")
		OS.delay_msec(500)
	assert( http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED ) # Make sure request finished well.
	print("response? ",http.has_response()) # Site might not have a response.
	if (http.has_response()):
		var headers = http.get_response_headers_as_dictionary() # Get response headers
		print("code: ",http.get_response_code()) # Show response code
		print("**headers:\\n",headers) # Show headers
		if (http.is_response_chunked()):
			print("Response is Chunked!")
		else:
			var bl = http.get_response_body_length()
			print("Response Length: ",bl)
		var rb = RawArray() # Array that will hold the data
		while(http.get_status()==HTTPClient.STATUS_BODY):
			http.poll()
			var chunk = http.read_response_body_chunk() # Get a chunk
			if (chunk.size()==0):
				OS.delay_usec(1000)
			else:
				rb = rb + chunk # Append to read buffer
		if raw:
			return rb
		else:
			return rb.get_string_from_ascii()
func get_json(host,port,file):
	var dict={}
	dict.parse_json(get(host,port,file))
	return dict

func _ready():
	randomize()
	num_images=get_json("xkcd.com",80,"/info.0.json").num
	get_image()
	set_process_input(true)

func _input(event):
	if event.is_action_pressed("ui_select"):
		get_image()

func get_image():
	var img=randi()%int(num_images)
	var data=get_json("xkcd.com",80,str("/",img,"/info.0.json"))
	print(data.img)
	var file = File.new()
	file.open(str("user://",img,".png"), 2)
	file.store_buffer(get("imgs.xkcd.com",80,str("/comics/",data.img.split('/')[4]),true))
	file.close()
	set_texture(load(str("user://",img,".png")))