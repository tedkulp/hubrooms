define ['cs!lib/app'], (app) ->
  app.server.get '/logout', (req, res) ->
    req.logout();
    res.redirect '/'
    app.stats.increment('logout.count')
