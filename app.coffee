express = require('express.io')
_ = require('underscore')
app = express().http().io()
mongoose = require('mongoose')
nconf = require('nconf')
githubApi = require('github')
processId = require('node-uuid').v4()
def = require("promised-io/promise").Deferred
console.log "Process ID: ", processId

# Load models
User = require('./models/user')
Channel = require('./models/channel')
Message = require('./models/message')

# Setup redis
redis = require('redis')
RedisStore = require('connect-redis')(express)
RedisClient = redis.createClient(nconf.get('redisPort'), nconf.get('redisHost'), { ttl: 3600 * 24 })

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

# Include all the passport stuff for talking
# with GitHub
passport = require('./passport')(app, nconf)

app.configure ->
  app.set('views', __dirname + '/views')
  app.set('view engine', 'jade')
  app.use(express.logger())
  app.use(express.cookieParser())
  app.use(express.bodyParser())
  app.use(express.methodOverride())
  app.use express.session
    secret: 'nyan cat is hungry'
    store: new RedisStore
      client: RedisClient

  passport.configure()

  app.use require('connect-assets')()

  app.use(app.router)
  app.use(express.static(__dirname + '/public'))

  app.io.set 'store', new express.io.RedisStore
    redisPub: redis.createClient(nconf.get('redisPort'), nconf.get('redisHost'))
    redisSub: redis.createClient(nconf.get('redisPort'), nconf.get('redisHost'))
    redisClient: redis.createClient(nconf.get('redisPort'), nconf.get('redisHost'))

passport.setup()

requireLogin = (req, res, next) ->
  if req.session and req.session.passport and req.session.passport.user
    next()
  else
    res.send(403)

app.get '/', (req, res) ->
  if req.user
    Channel
      .find
        users: req.user._id
      .exec (err, channels) ->
        res.render 'index',
          title: 'Home'
          user: req.user
          channels: channels
  else
    res.render 'home',
      title: 'Home'
      user: null

app.get '/logout', (req, res) ->
  req.logout();
  res.redirect '/'

app.get '/channels', requireLogin, (req, res) ->
  Channel
    .find
      users: req.session.passport.user._id
    .exec (err, channels) ->
      res.json(channels)

app.get '/channel_users', requireLogin, (req, res) ->
  #TODO> Handle no channel_id passed
  Channel
    .find
      _id: req.param('channel_id')
      users: req.session.passport.user._id
    .populate('users')
    .exec (err, channel) ->
      #TODO: Handle error
      RedisClient.smembers 'channel-' + req.param('channel_id'), (err, value) ->
        res.json _.map _.first(channel).users, (user) ->
          _.chain(user.toObject())
            .tap (theUser) ->
              theUser.present = _.contains(value, String(user._id))
            .value()

app.get '/messages', requireLogin, (req, res) ->
  Message
    .find
      channel_id: req.param('channel_id')
    .exec (err, messages) ->
      res.json(messages)

app.post '/messages', requireLogin, (req, res) ->
  message = new Message(req.body)
  message.user_id = req.user['_id']
  message.login = req.user.login
  message.name = req.user.name
  message.created_at = message.updated_at = new Date() # We don't trust clients
  message.save (err) ->
    res.json(message)
    unless err
      app.io.room(message.channel_id).broadcast('new-message', message)

renderChat = (req, res, user) ->
  res.render 'chat',
    title: 'Chat'
    user: user

#Setup all the sockets.io stuff
websockets = require('./websockets')(app, RedisClient, processId, reconcileSha).setup()

app.get /^\/(?!(?:css|js|img))([^\/]+)\/([^\/]+)\/leave$/, requireLogin, (req, res) ->
  channelName = "#{req.params[0]}/#{req.params[1]}"
  Channel.findChannelByName channelName, (err, channel) ->
    if channel?
      channel.removeUser req.user, (err, data) ->
        websockets.userRemovedFromChannel(req.user, channel)
        res.redirect '/'
    else
      res.redirect '/'

app.get /^\/(?!(?:css|js|img))([^\/]+)\/([^\/]+)$/, requireLogin, (req, res) ->
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
    else
      channelName = "#{req.params[0]}/#{req.params[1]}"
      Channel.findChannelByName channelName, (err, channel) ->
        # Does it exist? Are they a member of this channel yet?
        if !err? and channel?
          foundUser = _.find channel.users, (channelUser) ->
            String(channelUser) == String(req.user._id)
          if foundUser?
            renderChat req, res, req.user
          else
            channel.addUser req.user, (err, user) ->
              websockets.userAddedToChannel(req.user, channel)
              renderChat req, res, user

        # It doesn't exist -- we have to create the channel first
        else if !err?
          if !req.param('force_create')? and (githubChannelData.parent? or githubChannelData.source?)
            res.render 'ask-for-parent.jade',
              title: 'Ask for Parent'
              user: req.user
              channelName: channelName
              sourceName: githubChannelData.source.full_name
              parentName: githubChannelData.parent.full_name
          else
            Channel.createChannel channelName, req.user, (err, channel) ->
              unless err?
                websockets.userAddedToChannel(req.user, channel)
                renderChat req, res, req.user

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

process.on 'uncaughtException', (err) ->
  console.log "Uncaught Exception:", err
  gracefulShutdown ->
    process.exit()

app.listen(nconf.get('port'))
