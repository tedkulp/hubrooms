_ = require('underscore')

define ['cs!lib/app', 'cs!lib/redis_client', 'cs!lib/reconcile_sha', 'cs!models/channel'], (app, RedisClient, reconcileSha, Channel) ->
  return {
    setup: ->
      requirejs ['cs!models/channel'], (Channel) =>
        findChannels = (user, callback, socket, clientCount) ->
          Channel.findChannelsByJoinedUser user, (err, channels) ->
            if !err and channels
              _.each channels, (channel) ->
                callback(user, channel, socket, clientCount)

        joinChannel = (user, channel, socket) =>
          if socket?
            socket.join(channel['_id'])
          @userActiveInChannel(user, channel)
          app.stats.increment('websocket.join.count')

        leaveChannel = (user, channel, socketId, clientCount) =>
          if socket?
            socket.leave(channel['_id'])
          @userInactiveInChannel(user, channel)
          app.stats.increment('websocket.leave.count')

        app.server.io.sockets.on 'connection', (socket) =>
          if socket.handshake.session and socket.handshake.session.passport
            user = socket.handshake.session.passport.user
            socketId = socket.id

            RedisClient.lpush "process:#{app.processId}", user._id
            RedisClient.expire "process:#{app.processId}", 30

            reconcileSha().then (sha) ->
              RedisClient.evalsha sha, 0, (err, res) ->
                RedisClient.get "user:", (err, value) ->
                  if err or !value
                    value = 0
                  findChannels(socket.handshake.session.passport.user, joinChannel, socket, value)

            app.stats.increment('websocket.connection.count')

          socket.on 'disconnect', =>
            if socket.handshake.session and socket.handshake.session.passport
              user = socket.handshake.session.passport.user
              socketId = socket.id

              RedisClient.lrem "process:#{app.processId}", 1, user._id
              RedisClient.expire "process:#{app.processId}", 30

              reconcileSha().then (sha) ->
                RedisClient.evalsha sha, 0, (err, res) ->
                  RedisClient.get "user:", (err, value) ->
                    if err or !value
                      value = 0
                    findChannels(user, leaveChannel, socketId, value)

              app.stats.increment('websocket.disconnection.count')

      @

    userActiveInChannel: (user, channel) ->
      app.server.io.room(channel._id).broadcast 'active-user',
        user: user
        channel: channel

    userInactiveInChannel: (user, channel) ->
      app.server.io.room(channel._id).broadcast 'inactive-user',
        user: user
        channel: channel

    userAddedToChannel: (user, channel) ->
      app.server.io.room(channel._id).broadcast 'add-user',
        user: user
        channel: channel

    userRemovedFromChannel: (user, channel) ->
      app.server.io.room(channel._id).broadcast 'remove-user',
        user: user
        channel: channel
  }.setup()
