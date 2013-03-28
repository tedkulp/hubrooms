# Connect up socket.io
socket = io.connect()

# Let the server know we're here
socket.emit('ready')
