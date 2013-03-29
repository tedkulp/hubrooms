express = require('express.io')
app = express().http().io()
mongoose = require('mongoose')
User = require('./models/user')

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
  app.use(express.session({ secret: 'nyan cat is hungry' }))

  # Initialize Passport!  Also use passport.session() middleware, to support
  # persistent login sessions (recommended).
  app.use(passport.initialize())
  app.use(passport.session())

  app.use require('connect-assets')()

  app.use(app.router)
  app.use(express.static(__dirname + '/public'))

app.get '/', (req, res) ->
  res.render 'index',
    title: 'Home'
    user: req.user

app.get /^\/(?!(?:js|css|auth))[^\/]+?\/([^\/]+?)/, (req, res) ->
  res.render 'chat',
    title: 'Chat'
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

app.listen(3000)
