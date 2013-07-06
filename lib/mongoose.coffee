define ['cs!lib/app'], (app) ->
  mongoose = require('mongoose')
  require('mongoose-middleware').initialize(mongoose)
  mongoose.connect(app.conf.get('mongoUri'))
  mongoose
