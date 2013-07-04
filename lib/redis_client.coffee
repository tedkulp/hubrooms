redis = require('redis')

define ['cs!lib/app'], (app) ->
  redis.createClient(app.conf.get('redisPort'), app.conf.get('redisHost'))
