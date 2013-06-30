express = require('express.io')
connect = require('connect')
_ = require('underscore')
app = express().http().io()
mongoose = require('mongoose')
nconf = require('nconf')
githubApi = require('github')
processId = require('node-uuid').v4()
def = require("promised-io/promise").Deferred
crypto = require('crypto')
console.log "Process ID: ", processId

SDC = require('statsd-client')

# Load models
User = require('./models/user')
Channel = require('./models/channel')
Message = require('./models/message')

# Setup redis
redis = require('redis')
RedisStore = require('connect-redis')(express)
RedisClient = redis.createClient(nconf.get('redisPort'), nconf.get('redisHost'))

reconcileSha = ->
  reconcileFunction = "
    local keys_to_remove = redis.call('KEYS', 'user:*')
    for i=1, #keys_to_remove do
      redis.call('DEL', keys_to_remove[i])
    end

    local processes = redis.call('KEYS', 'process:*')
    for i=1, #processes do
      local users_in_process = redis.call('LRANGE', processes[i], 0, -1)
      for j=1, #users_in_process do
        redis.call('INCR', 'user:' .. users_in_process[j])
      end
    end
  "

  dfd = new def()
  RedisClient.script 'load', reconcileFunction, (err, res) ->
    dfd.resolve(res)
  dfd.promise

# Grab all our config vars
nconf.argv()
  .env()
  .file
    file: "./config/#{app.get('env')}.json"

github = new githubApi
  version: '3.0.0'

mongoose.connect(nconf.get('mongoUri'))
sdc = new SDC({host: nconf.get('statsdHost'), port: nconf.get('statsdPort'), debug: (nconf.get('statsdDebug') == "true")})

# Include all the passport stuff for talking
# with GitHub
passport = require('./lib/passport')(app, nconf, sdc)

app.configure ->
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.use(express.logger())
  app.use(express.cookieParser())
  app.use(express.bodyParser())
  app.use(express.methodOverride())

  redisStore = new RedisStore
    client: RedisClient

  sessionMiddleware = express.session
    secret: 'nyan cat is hungry'
    store: redisStore

  app.use (req, res, next) ->
    sessionMiddleware req, res, next

  passport.configure()

  assets = require 'connect-assets'
  jsPaths = require 'connect-assets-jspaths'

  app.use assets()
  jsPaths assets, console.log

  if app.get('env') == 'development'
    fileChangedCallback = (err, filePath) ->
      console.log "File Changed: #{filePath}"

    jsPaths assets, console.log, fileChangedCallback, (err, watcher) ->
      console.log "Watcher initialized"

  app.use(app.router)
  app.use(express.static(__dirname + '/public'))

  app.io.set 'store', new express.io.RedisStore
    redisPub: redis.createClient(nconf.get('redisPort'), nconf.get('redisHost'))
    redisSub: redis.createClient(nconf.get('redisPort'), nconf.get('redisHost'))
    # redisClient: redis.createClient(nconf.get('redisPort'), nconf.get('redisHost'))
    redisClient: RedisClient # Reuse the express connection

  # Code to handle a request to socket.io with just the apikey parameter
  # For hubot-hubrooms -- more stuff later
  # Wrap the original function from express.io in one of our own to check the
  # login and apikey and authorize it if it matches. Otherwise, process to the
  # original logic.
  origFunction = app.io.get('authorization')
  app.io.set 'authorization', (data, next) ->
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
            data.session = new connect.session.Session data, sessionData
            next null, true
    else
      return origFunction(data, next)

passport.setup()

requireLogin = (req, res, next) ->
  if req.session and req.session.passport and req.session.passport.user
    next()
  else
    res.send(403)

app.get '/', (req, res) ->
  start = new Date()
  if req.user
    Channel
      .find
        users: req.user._id
      .exec (err, channels) ->
        res.render 'index',
          title: 'Home'
          user: req.user
          env: app.get('env')
          channels: channels
          googleAnalyticsId: nconf.get('googleAnalyticsId')
          googleAnalyticsHostname: nconf.get('googleAnalyticsHostname')
        sdc.increment('home.user.visit')
        sdc.timing('home.user.time', start)
  else
    res.render 'home',
      title: 'Home'
      user: null
      env: app.get('env')
      googleAnalyticsId: nconf.get('googleAnalyticsId')
      googleAnalyticsHostname: nconf.get('googleAnalyticsHostname')
    sdc.increment('home.anonymous.visit')
    sdc.timing('home.anonymous.time', start)

app.get '/logout', (req, res) ->
  req.logout();
  res.redirect '/'
  sdc.increment('logout.count')

app.get '/channels', requireLogin, (req, res) ->
  start = new Date()
  Channel
    .find
      users: req.session.passport.user._id
    .exec (err, channels) ->
      res.json(channels)
      sdc.timing('channels.received.time', start)

app.get '/channel_users', requireLogin, (req, res) ->
  #TODO> Handle no channel_id passed
  start = new Date()
  Channel
    .find
      _id: req.param('channel_id')
      users: req.session.passport.user._id
    .populate('users')
    .exec (err, channel) ->
      #TODO: Handle error
      users = _.map _.first(channel).users, (user) ->
        user.toObject()
      RedisClient.multi(_.map users, (user) ->
        ["get", "user:#{user._id}"]
      ).exec (err, replies) ->
        _.each users, (e, i) ->
          users[i].present = replies[i] != null and replies[i] > 0
        res.json users
        sdc.timing('channel_users.received.time', start)

app.get '/messages', requireLogin, (req, res) ->
  start = new Date()
  Message
    .find
      channel_id: req.param('channel_id')
    .exec (err, messages) ->
      res.json(messages)
      sdc.timing('messages.received.time', start)

app.io.route 'send-message', (req) ->
  start = new Date()
  message = new Message(req.data)
  # message.user_id = req.user['_id']
  message.user_id = req.session.passport.user._id
  message.login = req.session.passport.user.login
  message.name = req.session.passport.user.name
  message.created_at = message.updated_at = new Date() # We don't trust clients
  message.save (err) ->
    res.json(message) if res?
    unless err
      app.io.room(message.channel_id).broadcast('new-message', message)
    sdc.increment('message.sent.count')
    sdc.timing('messages.sent.time', start)

app.post '/messages', requireLogin, (req, res) ->
  start = new Date()
  message = new Message(req.body)
  message.user_id = req.user['_id']
  message.login = req.user.login
  message.name = req.user.name
  message.created_at = message.updated_at = new Date() # We don't trust clients
  message.save (err) ->
    res.json(message)
    unless err
      app.io.room(message.channel_id).broadcast('new-message', message)
    sdc.increment('message.sent.count')
    sdc.timing('messages.sent.time', start)

renderChat = (req, res, user) ->
  res.render 'chat',
    title: 'Chat'
    user: user
    env: app.get('env')
    googleAnalyticsId: nconf.get('googleAnalyticsId')
    googleAnalyticsHostname: nconf.get('googleAnalyticsHostname')

#Setup all the sockets.io stuff
websockets = require('./lib/websockets')(app, RedisClient, processId, reconcileSha, sdc).setup()

app.get /^\/(?!(?:css|js|img))([^\/]+)\/([^\/]+)\/leave$/, requireLogin, (req, res) ->
  start = new Date()
  channelName = "#{req.params[0]}/#{req.params[1]}"
  Channel.findChannelByName channelName, (err, channel) ->
    if channel?
      channel.removeUser req.user, (err, data) ->
        websockets.userRemovedFromChannel(req.user, channel)
        res.redirect '/'
        sdc.increment('channel.left.count')
        sdc.timing('channel.left.time', start)
    else
      res.redirect '/'

app.get /^\/(?!(?:css|js|img))([^\/]+)\/([^\/]+)$/, requireLogin, (req, res) ->
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
        env: app.get('env')
        googleAnalyticsId: nconf.get('googleAnalyticsId')
        googleAnalyticsHostname: nconf.get('googleAnalyticsHostname')
        sdc.increment('channel.404.count')
        sdc.timing('channel.404.time', start)
    else
      channelName = "#{req.params[0]}/#{req.params[1]}"
      Channel.findChannelByName channelName, (err, channel) ->
        # Does it exist? Are they a member of this channel yet?
        if !err? and channel?
          foundUser = _.find channel.users, (channelUser) ->
            String(channelUser) == String(req.user._id)
          if foundUser?
            renderChat req, res, req.user
            sdc.increment('channel.render.count')
            sdc.timing('channel.render.time', start)
          else
            channel.addUser req.user, (err, user) ->
              websockets.userAddedToChannel(req.user, channel)
              renderChat req, res, user
              sdc.increment('channel.join.count')
              sdc.timing('channel.join.time', start)

        # It doesn't exist -- we have to create the channel first
        else if !err?
          if !req.param('force_create')? and (githubChannelData.parent? or githubChannelData.source?)
            res.render 'ask-for-parent.jade',
              title: 'Ask for Parent'
              user: req.user
              env: app.get('env')
              googleAnalyticsId: nconf.get('googleAnalyticsId')
              googleAnalyticsHostname: nconf.get('googleAnalyticsHostname')
              channelName: channelName
              sourceName: githubChannelData.source.full_name
              parentName: githubChannelData.parent.full_name
          else
            Channel.createChannel channelName, req.user, (err, channel) ->
              unless err?
                websockets.userAddedToChannel(req.user, channel)
                renderChat req, res, req.user
                sdc.increment('channel.create.count')
                sdc.timing('channel.create.time', start)

setInterval ->
  RedisClient.expire "process:#{processId}", 30
, 30 * 1000

reconcileSha().then (sha) ->
  setInterval ->
    RedisClient.evalsha sha, 0, (err, res) ->
      # Nothign for now
  , 15 * 1000

gracefulShutdown = (callback) ->
  console.log "shutdown"
  reconcileSha().then (sha) ->
    RedisClient.del("process:#{processId}")
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

app.listen(nconf.get('port'))
