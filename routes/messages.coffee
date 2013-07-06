define ['cs!lib/app', 'cs!lib/require_login', 'cs!models/message'], (app, requireLogin, Message) ->
  app.server.get '/messages', requireLogin, (req, res) ->
    options =
      start: req.param('start') || 0
      count: 100
      sort:
        desc: '_id'
    start = new Date()
    Message
      .find
        channel_id: req.param('channel_id')
      .order(options)
      .page options, (err, messages) ->
        unless req.param('no_reverse')
          messages.results.reverse()
        res.json(messages)
        app.stats.timing('messages.received.time', start)

  app.server.post '/messages', requireLogin, (req, res) ->
    start = new Date()
    message = new Message(req.body)
    message.user_id = req.user['_id']
    message.login = req.user.login
    message.name = req.user.name
    message.created_at = message.updated_at = new Date() # We don't trust clients
    message.save (err) ->
      res.json(message)
      unless err
        app.server.io.room(message.channel_id).broadcast('new-message', message)
      app.stats.increment('message.sent.count')
      app.stats.timing('messages.sent.time', start)
