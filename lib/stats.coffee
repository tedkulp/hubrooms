define ->
  SDC = require('statsd-client')

  sdc: null
  initialize: (app) ->
    @sdc = new SDC({host: app.conf.get('statsdHost'), port: app.conf.get('statsdPort'), debug: (app.conf.get('statsdDebug') == "true")})
    @
  increment: (key) ->
    @sdc.increment(key)
    @
  timing: (key, time) ->
    @sdc.timing(key, time)
    @
