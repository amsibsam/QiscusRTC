
#caller
1. connnect websocket and send register or login
	- got response wss success
2. send room create
	- got success create room. if success automate join. if false mybe duplicate end call
== waiting wss event answer/call reject ==
3. got event call accept
	- peer connction send offer


#cellee
1. connnect websocket
	- got response wss success
2. send join room
	- if success call session is active, else call session expired
3. send call ack

success sync 
. if Accept call, send call accept. else reject call send call reject


