define ['marionette', 'socket_io'], (marionette, io) ->
  Hubrooms = window.Hubrooms = new Backbone.Marionette.Application()
  Socket = window.Socket = io.connect()

  Hubrooms.addRegions
    channelNav      : '#channel_nav_area'
    messages        : '#messages'
    userList        : '#userlist'
    sendMessageArea : '#send_message_area'

  # Move me to the main chat page
  # $ ->
  #   offline = $("<div></div>")
  #   .html("The connection has been disconnected! <br /> " +
  #     "Please go back online to use this service.")
  #   .dialog
  #     autoOpen: false,
  #     modal:    true,
  #     width:    330,
  #     resizable: false,
  #     closeOnEscape: false,
  #     title: "Connection",
  #     open: (event, ui) ->
  #       $(".ui-dialog-titlebar-close").hide()

  #   Socket.on 'connect', (data) ->
  #     offline.dialog("close")

  #   Socket.on 'disconnect', (data) ->
  #     offline.dialog("open")

  #   Hubrooms.start()

  return Hubrooms
