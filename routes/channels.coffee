define ['cs!lib/app', 'cs!lib/require_login', 'cs!models/channel'], (app, requireLogin, Channel) ->
  app.server.get '/channels', requireLogin, (req, res) ->
    start = new Date()
    Channel
      .find
        users: req.session.passport.user._id
      .exec (err, channels) ->
        res.json(channels)
        app.stats.timing('channels.received.time', start)
