express = require('express.io')
_ = require('underscore')
app = express().http().io()
mongoose = require('mongoose')
User = require('./models/user')
Channel = require('./models/channel')
Message = require('./models/message')

redis = require('redis')
RedisStore = require('connect-redis')(express)
RedisClient = redis.createClient()

mongoose.connect('mongodb://shiftrefresh:N0g1M2o0@dharma.mongohq.com:10060/hubrooms-dev')

passport = require 'passport'
GitHubStrategy = require('passport-github').Strategy

GITHUB_CLIENT_ID = "afc88baef243936063c4"
GITHUB_CLIENT_SECRET = "d11f5ed26520e9f020d98489d0976e9de2b6ea24"

passport.serializeUser (user, done) ->
  done(null, user)

passport.deserializeUser (obj, done) ->
  done(null, obj)

passport.use new GitHubStrategy
  clientID: GITHUB_CLIENT_ID
  clientSecret: GITHUB_CLIENT_SECRET
  callbackURL: "http://hubrooms.dev:3000/auth/github/callback"
, (accessToken, refreshToken, profile, done) ->
  User.findOrCreate
    external_id: profile.id
  ,
    login: profile.username
    name: profile.displayName
    location: profile._json.location
    email: profile._json.email
    url: profile.profileUrl
  ,
    upsert: true
  ,
    (err, user) ->
      done(null, user) unless err

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

  # Initialize Passport!  Also use passport.session() middleware, to support
  # persistent login sessions (recommended).
  app.use(passport.initialize())
  app.use(passport.session())

  app.use require('connect-assets')()

  app.use(app.router)
  app.use(express.static(__dirname + '/public'))

  app.io.set 'store', new express.io.RedisStore
    redisPub: redis.createClient()
    redisSub: redis.createClient()
    redisClient: redis.createClient()

requireLogin = (req, res, next) ->
  if req.session and req.session.passport and req.session.passport.user
    next()
  else
    res.send(403)

app.get '/', (req, res) ->
  res.render 'index',
    title: 'Home'
    user: req.user

app.get '/logout', (req, res) ->
  req.logout();
  res.redirect '/'

app.get '/auth/github',
  passport.authenticate('github'),
  (req, res) ->
    # Never called

app.get '/auth/github/callback',
  passport.authenticate('github', { failureRedirect: '/login' }),
  (req, res) ->
    res.redirect('/')

app.get '/channels', requireLogin, (req, res) ->
  Channel
    .find
      users: req.session.passport.user._id
    .exec (err, channels) ->
      res.json(channels)

app.get '/channel_users', requireLogin, (req, res) ->
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
  message.save (err) ->
    res.json(message)
    unless err
      app.io.room(message.channel_id).broadcast('new-message', message)

app.get /^\/(?!(?:css|js|img))([^\/]+)\/([^\/]+)$/, requireLogin, (req, res) ->
  res.render 'chat',
    title: 'Chat'
    user: req.user

findChannels = (user, callback, socket, clientCount) ->
  Channel
    .find
      users: user._id
    .exec (err, channels) ->
      if !err and channels
        _.each channels, (channel) ->
          callback(user, channel, socket, clientCount)

openSessions = new Object

joinChannel = (user, channel, socket) ->
  # console.log "joining channel", channel.name, user._id
  RedisClient.sadd('channel-' + channel._id, user._id)
  if socket?
    socket.join(channel['_id'])
    openSessions[socket.id].channelIds.push(channel._id)

leaveChannel = (user, channel, socketId, clientCount) ->
  # console.log "leaving channel", channel.name, user._id
  RedisClient.srem('channel-' + channel._id, user._id) if clientCount? and clientCount < 1

app.io.sockets.on 'connection', (socket) ->
  if socket.handshake.session and socket.handshake.session.passport
    openSessions[socket.id] = socket.handshake.session.passport.user
    openSessions[socket.id].channelIds ||= []

    RedisClient.incr('user-' + socket.handshake.session.passport.user._id)
    RedisClient.get 'user-' + socket.handshake.session.passport.user._id, (err, value) ->
      if err or !value
        value = 0

      findChannels(socket.handshake.session.passport.user, joinChannel, socket, value)

  socket.on 'disconnect', ->
    if socket.handshake.session and socket.handshake.session.passport
      user = socket.handshake.session.passport.user
      socketId = socket.id

      RedisClient.decr('user-' + user._id)
      RedisClient.get 'user-' + user._id, (err, value) ->
        if err or !value
          value = 0

        findChannels(user, leaveChannel, socketId, value)

        delete openSessions[socketId]

gracefulShutdown = ->
  _.each openSessions, (user, socketId) ->
    RedisClient.decr('user-' + user._id)
    _.each user.channelIds, (channelId) ->
      RedisClient.srem('channel-' + channelId, user._id)
  process.exit()

process.on 'SIGINT', ->
  gracefulShutdown()

app.listen(3000)
