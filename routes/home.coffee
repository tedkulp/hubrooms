define ['cs!lib/app', 'cs!models/channel'], (app, Channel) ->
  app.server.get '/', (req, res) ->
    start = new Date()
    if req.user
      Channel
        .find
          users: req.user._id
        .exec (err, channels) ->
          res.render 'index',
            title: 'Home'
            user: req.user
            env: app.server.get('env')
            channels: channels
            googleAnalyticsId: app.conf.get('googleAnalyticsId')
            googleAnalyticsHostname: app.conf.get('googleAnalyticsHostname')
          app.stats.increment('home.user.visit')
          app.stats.timing('home.user.time', start)
    else
      res.render 'home',
        title: 'Home'
        user: null
        env: app.server.get('env')
        googleAnalyticsId: app.conf.get('googleAnalyticsId')
        googleAnalyticsHostname: app.conf.get('googleAnalyticsHostname')
      app.stats.increment('home.anonymous.visit')
      app.stats.timing('home.anonymous.time', start)
