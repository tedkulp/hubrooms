define ->
  express = require 'express.io'

  server = express().http().io()
  server.configure ->
    server.set('views', __dirname + '/../../../views')
    server.set('view engine', 'jade')

    server.use(express.logger())
    server.use(express.cookieParser())
    server.use(express.bodyParser())
    server.use(express.methodOverride())

    server.use(server.router)
    server.use(express.static(__dirname + '/../../../public'))

  server
