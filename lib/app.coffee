define ['cs!lib/stats'], (stats) ->
  express = require('express.io')

  {
    express    : express
    processId  : require('node-uuid').v4()
    server     : express().http().io()
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
