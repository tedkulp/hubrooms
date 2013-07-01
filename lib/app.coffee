define ['cs!lib/stats', 'cs!lib/server'], (stats, server) ->
  express = require('express.io')

  {
    express    : express
    server     : server
    processId  : require('node-uuid').v4()
    conf       : require('nconf')
    stats      : null
    initialize : ->
      @stats = stats.initialize(@)

      # Grab all our config vars
      @conf.argv()
        .env()
        .file
          file: "./config/#{@server.get('env')}.json"

      @
  }.initialize()
