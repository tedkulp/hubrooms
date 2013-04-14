passport = require 'passport'
GitHubStrategy = require('passport-github').Strategy
User = require('./models/user')

module.exports = (app, nconf, sdc) ->
  configure: ->
    app.use(passport.initialize())
    app.use(passport.session())

  setup: ->
    passport.serializeUser (user, done) ->
      done(null, user)

    passport.deserializeUser (obj, done) ->
      done(null, obj)

    passport.use new GitHubStrategy
      clientID: nconf.get('githubClientId')
      clientSecret: nconf.get('githubClientSecret')
      callbackURL: nconf.get('githubCallback')
    , (accessToken, refreshToken, profile, done) ->
      User.findOrCreate
        external_id: profile.id
      ,
        login: profile.username
        name: profile.displayName
        location: profile._json.location
        email: profile._json.email
        url: profile.profileUrl
        access_token: accessToken
        refresh_token: refreshToken
      ,
        upsert: true
      ,
        (err, user) ->
          done(null, user) unless err


    app.get '/auth/github',
      passport.authenticate('github'),
      (req, res) ->
        # Never called

    app.get '/auth/github/callback',
      passport.authenticate('github', { failureRedirect: '/login' }),
      (req, res) ->
        res.redirect('/')
        sdc.increment('github.callback.count')
