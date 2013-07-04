requirejs = require('requirejs')
requirejs.config
  baseUrl: './'
  nodeRequire: require
  paths:
    cs: 'plugins/cs'

global.basePath = __dirname

_ = require('underscore')
crypto = require('crypto')

githubApi = require('github')
github = new githubApi
  version: '3.0.0'

requirejs ['cs!lib/app', 'cs!models/user', 'cs!models/channel',
  'cs!models/message', 'cs!lib/passport', 'cs!lib/redis_client',
  'cs!lib/require_login', 'cs!lib/render_chat', 'cs!lib/reconcile_sha',
  'cs!lib/websockets'], (app, User, Channel, Message, passport, RedisClient, requireLogin, renderChat, reconcileSha, websockets) ->

  console.log "Process ID: ", app.processId

  # Setup redis
  redis = require('redis')
  RedisStore = require('connect-redis')(app.express)
  # RedisClient = redis.createClient(app.conf.get('redisPort'), app.conf.get('redisHost'))

  app.server.configure ->

    app.server.io.set 'store', new app.express.io.RedisStore
      redisPub: redis.createClient(app.conf.get('redisPort'), app.conf.get('redisHost'))
      redisSub: redis.createClient(app.conf.get('redisPort'), app.conf.get('redisHost'))
      # redisClient: redis.createClient(app.conf.get('redisPort'), app.conf.get('redisHost'))
      redisClient: RedisClient # Reuse the express connection

    # Code to handle a request to socket.io with just the apikey parameter
    # For hubot-hubrooms -- more stuff later
    # Wrap the original function from express.io in one of our own to check the
    # login and apikey and authorize it if it matches. Otherwise, process to the
    # original logic.
    origFunction = app.server.io.get('authorization')
    app.server.io.set 'authorization', (data, next) ->
      if data.query? and data.query.apikey? and data.query.login?
        User.findOne
          login: data.query.login
          api_key: data.query.apikey
        ,
          (err, user) ->
            return next 'apikey or login not valid', false if err? or !user?
            shasum = crypto.createHash('sha1')
            shasum.update("#{data.query.login}::#{data.query.apikey}")
            sessionId = shasum.digest('hex')
            data.sessionID = sessionId
            redisStore.get sessionId, (error, session) ->
              return next error if error?
              sessionData =
                passport:
                  user: user
              data.session = new require('connect').session.Session data, sessionData
              next null, true
      else
        return origFunction(data, next)

  app.events.on 'middlewareLoaded', ->
    passport.setup(app)

    requirejs ['cs!routes/index'], (index) ->
      app.server.get /^\/(?!(?:css|js|img))([^\/]+)\/([^\/]+)\/leave$/, requireLogin, (req, res) ->
        start = new Date()
        channelName = "#{req.params[0]}/#{req.params[1]}"
        Channel.findChannelByName channelName, (err, channel) ->
          if channel?
            channel.removeUser req.user, (err, data) ->
              websockets.userRemovedFromChannel(req.user, channel)
              res.redirect '/'
              app.stats.increment('channel.left.count')
              app.stats.timing('channel.left.time', start)
          else
            res.redirect '/'

      app.server.get /^\/(?!(?:css|js|img))([^\/]+)\/([^\/]+)$/, requireLogin, (req, res) ->
        start = new Date()
        github.authenticate
          type: 'oauth'
          token: req.user.access_token
        github.repos.get
          user: req.params[0]
          repo: req.params[1]
        , (err, githubChannelData) ->
          if err
            # Does not exist or no permission
            res.status(404)
            res.render '404-nochannel.jade',
              title: 'Repository Does Not Exist/No Permission'
              user: req.user
              env: app.server.get('env')
              googleAnalyticsId: app.conf.get('googleAnalyticsId')
              googleAnalyticsHostname: app.conf.get('googleAnalyticsHostname')
              app.stats.increment('channel.404.count')
              app.stats.timing('channel.404.time', start)
          else
            channelName = "#{req.params[0]}/#{req.params[1]}"
            Channel.findChannelByName channelName, (err, channel) ->
              # Does it exist? Are they a member of this channel yet?
              if !err? and channel?
                foundUser = _.find channel.users, (channelUser) ->
                  String(channelUser) == String(req.user._id)
                if foundUser?
                  renderChat req, res, req.user
                  app.stats.increment('channel.render.count')
                  app.stats.timing('channel.render.time', start)
                else
                  channel.addUser req.user, (err, user) ->
                    websockets.userAddedToChannel(req.user, channel)
                    renderChat req, res, user
                    app.stats.increment('channel.join.count')
                    app.stats.timing('channel.join.time', start)

              # It doesn't exist -- we have to create the channel first
              else if !err?
                if !req.param('force_create')? and (githubChannelData.parent? or githubChannelData.source?)
                  res.render 'ask-for-parent.jade',
                    title: 'Ask for Parent'
                    user: req.user
                    env: app.server.get('env')
                    googleAnalyticsId: app.conf.get('googleAnalyticsId')
                    googleAnalyticsHostname: app.conf.get('googleAnalyticsHostname')
                    channelName: channelName
                    sourceName: githubChannelData.source.full_name
                    parentName: githubChannelData.parent.full_name
                else
                  Channel.createChannel channelName, req.user, (err, channel) ->
                    unless err?
                      websockets.userAddedToChannel(req.user, channel)
                      renderChat req, res, req.user
                      app.stats.increment('channel.create.count')
                      app.stats.timing('channel.create.time', start)

  setInterval ->
    RedisClient.expire "process:#{app.processId}", 30
  , 30 * 1000

  reconcileSha().then (sha) ->
    setInterval ->
      RedisClient.evalsha sha, 0, (err, res) ->
        # Nothign for now
    , 15 * 1000

  gracefulShutdown = (callback) ->
    console.log "shutdown"
    reconcileSha().then (sha) ->
      RedisClient.del("process:#{app.processId}")
      RedisClient.evalsha sha, 0, (err, res) ->
        callback() if callback?

  process.once 'SIGINT', ->
    gracefulShutdown ->
      process.kill(process.pid, 'SIGINT')

  process.once 'SIGUSR2', ->
    gracefulShutdown ->
      process.kill(process.pid, 'SIGUSR2')

  # process.on 'uncaughtException', (err) ->
  #   console.log "Uncaught Exception:", err
  #   gracefulShutdown ->
  #     process.exit()

  app.server.listen(app.conf.get('port'))
