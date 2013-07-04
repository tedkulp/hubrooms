define ['cs!lib/app'], (app) ->
  (req, res, user) ->
    res.render 'chat',
      title: 'Chat'
      user: user
      env: app.server.get('env')
      startApp: true
      googleAnalyticsId: app.conf.get('googleAnalyticsId')
      googleAnalyticsHostname: app.conf.get('googleAnalyticsHostname')
