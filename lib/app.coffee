define ['cs!lib/stats', 'cs!lib/server'], (stats, server) ->
  express = require('express.io')
  events = require('events')

  {
    express    : express
    events     : new events.EventEmitter()
    server     : server
    processId  : require('node-uuid').v4()
    conf       : require('nconf')
    stats      : null
    errbit     : null
    initialize : ->
      @stats = stats.initialize(@)

      # Grab all our config vars
      @conf.argv()
        .env()
        .file
          file: "./config/#{@server.get('env')}.json"

      if @conf.get('errbitApiKey') and @conf.get('errbitApiKey') != ''
        @errbit = require('airbrake').createClient(@conf.get('errbitApiKey'))

      @
  }.initialize()
