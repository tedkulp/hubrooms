define ['cs!lib/app', 'cs!models/message'], (app, Message) ->
  app.server.io.route 'send-message', (req) ->
    start = new Date()
    message = new Message(req.data)
    # message.user_id = req.user['_id']
    message.user_id = req.session.passport.user._id
    message.login = req.session.passport.user.login
    message.name = req.session.passport.user.name
    message.created_at = message.updated_at = new Date() # We don't trust clients
    message.save (err) ->
      res.json(message) if res?
      unless err
        app.server.io.room(message.channel_id).broadcast('new-message', message)
      app.stats.increment('message.sent.count')
      app.stats.timing('messages.sent.time', start)
