define ['cs!lib/app'], (app) ->
  mongoose = require('mongoose')
  mongoose.connect(app.conf.get('mongoUri'))
  mongoose
