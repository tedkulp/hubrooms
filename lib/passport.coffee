define ->
  passport = require 'passport'
  GitHubStrategy = require('passport-github').Strategy

  return {
    configure: (server) ->
      server.use(passport.initialize())
      server.use(passport.session())

    setup: (app) ->
      passport.serializeUser (user, done) ->
        done(null, user)

      passport.deserializeUser (obj, done) ->
        done(null, obj)

      requirejs ['cs!models/user'], (User) ->
        passport.use new GitHubStrategy
          clientID: app.conf.get('githubClientId')
          clientSecret: app.conf.get('githubClientSecret')
          callbackURL: app.conf.get('githubCallback')
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

      app.server.get '/auth/github',
        passport.authenticate('github'),
        (req, res) ->
          # Never called

      app.server.get '/auth/github/callback',
        passport.authenticate('github', { failureRedirect: '/login' }),
        (req, res) ->
          res.redirect('/')
          app.stats.increment('github.callback.count')
  }
