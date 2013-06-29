define ['app', 'socket_io', 'controller', 'models/channel', 'models/message', 'models/user'], (Hubrooms, io, controller, channelModule, messageModule, userModule) ->
  Hubrooms.on 'initialize:after', ->
    Backbone.history.start({pushState: true})

    # Let the server know we're here
    Socket.emit('ready')

    # Move me somewhere better
    Socket.on 'new-message', (data) ->
      message = new messageModule.Message(data)
      if message
        currentChannel = Hubrooms.controller.channels.findCurrent()
        if currentChannel.get('_id') == message.get('channel_id')
          Hubrooms.controller.messages.add(message)
        else
          # Handle the highlighting if name is mentioned

    Socket.on 'add-user', (data) ->
      user = new userModule.User(data.user)
      channel = new channelModule.Channel(data.channel)
      if user? and channel?
        currentChannel = controller.channels.findCurrent()
        if currentChannel.get('_id') == channel.get('_id')
          controller.users.add(user)

    Socket.on 'remove-user', (data) ->
      user = new userModule.User(data.user)
      channel = new channelModule.Channel(data.channel)
      if user? and channel?
        currentChannel = controller.channels.findCurrent()
        if currentChannel.get('_id') == channel.get('_id')
          controller.users.remove(Hubrooms.controller.users.where({_id: user.get('_id')}))

    Socket.on 'active-user', (data) ->
      user = new userModule.User(data.user)
      channel = new channelModule.Channel(data.channel)
      if user? and channel?
        currentChannel = controller.channels.findCurrent()
        if currentChannel.get('_id') == channel.get('_id')
          controller.users.get(user).set('present', true)

    Socket.on 'inactive-user', (data) ->
      user = new userModule.User(data.user)
      channel = new channelModule.Channel(data.channel)
      if user? and channel?
        currentChannel = controller.channels.findCurrent()
        if currentChannel.get('_id') == channel.get('_id')
          controller.users.get(user).set('present', false)
