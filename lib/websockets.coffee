Channel = require('../models/channel')
_ = require('underscore')

module.exports = (app, RedisClient, processId, reconcileSha, sdc) ->
  setup: ->
    findChannels = (user, callback, socket, clientCount) ->
      Channel.findChannelsByJoinedUser user, (err, channels) ->
        if !err and channels
          _.each channels, (channel) ->
            callback(user, channel, socket, clientCount)

    joinChannel = (user, channel, socket) =>
      if socket?
        socket.join(channel['_id'])
      @userActiveInChannel(user, channel)
      sdc.increment('websocket.join.count')

    leaveChannel = (user, channel, socketId, clientCount) =>
      if socket?
        socket.leave(channel['_id'])
      @userInactiveInChannel(user, channel)
      sdc.increment('websocket.leave.count')

    app.io.sockets.on 'connection', (socket) =>
      if socket.handshake.session and socket.handshake.session.passport
        user = socket.handshake.session.passport.user
        socketId = socket.id

        RedisClient.lpush "process:#{processId}", user._id
        RedisClient.expire "process:#{processId}", 30

        reconcileSha().then (sha) ->
          RedisClient.evalsha sha, 0, (err, res) ->
            RedisClient.get "user:", (err, value) ->
              if err or !value
                value = 0
              findChannels(socket.handshake.session.passport.user, joinChannel, socket, value)

        sdc.increment('websocket.connection.count')

      socket.on 'disconnect', =>
        if socket.handshake.session and socket.handshake.session.passport
          user = socket.handshake.session.passport.user
          socketId = socket.id

          RedisClient.lrem "process:#{processId}", 1, user._id
          RedisClient.expire "process:#{processId}", 30

          reconcileSha().then (sha) ->
            RedisClient.evalsha sha, 0, (err, res) ->
              RedisClient.get "user:", (err, value) ->
                if err or !value
                  value = 0
                findChannels(user, leaveChannel, socketId, value)

          sdc.increment('websocket.disconnection.count')

    @

  userActiveInChannel: (user, channel) ->
    app.io.room(channel._id).broadcast 'active-user',
      user: user
      channel: channel

  userInactiveInChannel: (user, channel) ->
    app.io.room(channel._id).broadcast 'inactive-user',
      user: user
      channel: channel

  userAddedToChannel: (user, channel) ->
    app.io.room(channel._id).broadcast 'add-user',
      user: user
      channel: channel

  userRemovedFromChannel: (user, channel) ->
    app.io.room(channel._id).broadcast 'remove-user',
      user: user
      channel: channel