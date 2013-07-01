define ->
  express = require 'express.io'

  server = express().http().io()
  server.configure ->
    requirejs ['cs!lib/passport', 'cs!lib/app'], (passport, app) ->
      redis = require('redis')
      RedisStore = require('connect-redis')(express)
      RedisClient = redis.createClient(app.conf.get('redisPort'), app.conf.get('redisHost'))

      server.set('views', __dirname + '/../../../views')
      server.set('view engine', 'jade')

      server.use(express.logger())
      server.use(express.cookieParser())
      server.use(express.bodyParser())
      server.use(express.methodOverride())

      redisStore = new RedisStore
        client: RedisClient

      sessionMiddleware = app.express.session
        secret: 'nyan cat is hungry'
        store: redisStore

      app.server.use (req, res, next) ->
        sessionMiddleware req, res, next

      assets = require 'connect-assets'
      jsPaths = require 'connect-assets-jspaths'

      app.server.use assets()
      jsPaths assets, console.log

      if app.server.get('env') == 'development'
        fileChangedCallback = (err, filePath) ->
          console.log "File Changed: #{filePath}"

        jsPaths assets, console.log, fileChangedCallback, (err, watcher) ->
          console.log "Watcher initialized"

      passport.configure(server)

      server.use(server.router)
      server.use(express.static(__dirname + '/../../../public'))

      app.events.emit('middlewareLoaded')

  server
