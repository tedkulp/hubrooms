_ = require('underscore')

define ['cs!lib/app', 'cs!lib/require_login', 'cs!models/channel', 'cs!lib/redis_client'], (app, requireLogin, Channel, RedisClient) ->
  app.server.get '/channel_users', requireLogin, (req, res) ->
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
          app.stats.timing('channel_users.received.time', start)
