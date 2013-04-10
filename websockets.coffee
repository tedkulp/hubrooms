Channel = require('./models/channel')
_ = require('underscore')

module.exports = (app, RedisClient) ->
  setup: ->
    @openSessions = new Object

    findChannels = (user, callback, socket, clientCount) ->
      Channel.findChannelsByJoinedUser user, (err, channels) ->
        if !err and channels
          _.each channels, (channel) ->
            callback(user, channel, socket, clientCount)

    joinChannel = (user, channel, socket) =>
      # console.log "joining channel", channel.name, user._id
      RedisClient.sadd('channel-' + channel._id, user._id)
      if socket?
        socket.join(channel['_id'])
        @openSessions[socket.id].channelIds.push(channel._id)

    leaveChannel = (user, channel, socketId, clientCount) ->
      # console.log "leaving channel", channel.name, user._id
      RedisClient.srem('channel-' + channel._id, user._id) if clientCount? and clientCount < 1

    app.io.sockets.on 'connection', (socket) =>
      if socket.handshake.session and socket.handshake.session.passport
        @openSessions[socket.id] = socket.handshake.session.passport.user
        @openSessions[socket.id].channelIds ||= []

        RedisClient.incr('user-' + socket.handshake.session.passport.user._id)
        RedisClient.get 'user-' + socket.handshake.session.passport.user._id, (err, value) ->
          if err or !value
            value = 0

          findChannels(socket.handshake.session.passport.user, joinChannel, socket, value)

      socket.on 'disconnect', =>
        if socket.handshake.session and socket.handshake.session.passport
          user = socket.handshake.session.passport.user
          socketId = socket.id

          RedisClient.decr('user-' + user._id)
          RedisClient.get 'user-' + user._id, (err, value) =>
            if err or !value
              value = 0

            findChannels(user, leaveChannel, socketId, value)

            delete @openSessions[socketId]
    @

  sessions: ->
    @openSessions
