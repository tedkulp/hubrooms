express = require('express.io')
app = express().http().io()

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
  process.nextTick ->
    done(null, profile)

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

  app.use(app.router)
  app.use(express.static(__dirname + '/public'))

app.get '/', (req, res) ->
  res.render 'index',
    title: 'Home'

app.get '/auth/github',
  passport.authenticate('github'),
  (req, res) ->

app.get '/auth/github/callback',
  passport.authenticate('github', { failureRedirect: '/login' }),
  (req, res) ->
    console.log req.user
    res.redirect('/')

app.listen(3000)
