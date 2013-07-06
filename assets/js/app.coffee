define ['marionette', 'socket_io', 'offline'], (marionette, io, offline) ->
  Hubrooms = window.Hubrooms = new Backbone.Marionette.Application()

  Hubrooms.addRegions
    channelNav      : '#channel_nav_area'
    messages        : '#messages-container'
    userList        : '#userlist'
    sendMessageArea : '#send_message_area'

  # Setup our socket.io connect and events
  Socket = window.Socket = io.connect()

  Socket.on 'connect', (data) ->
    offline.dialog("close")

  Socket.on 'disconnect', (data) ->
    offline.dialog("open")

  return Hubrooms
