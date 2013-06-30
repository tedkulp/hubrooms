define ['cs!lib/stats'], (stats) ->
  express = require('express.io')

  obj = 
    server : express().http().io()
    conf   : require('nconf')
    stats  : null

  obj.stats = stats.initialize(obj)
  obj
