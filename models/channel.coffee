define ['cs!lib/mongoose'], (mongoose) ->
  _ = require('underscore')
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId
  timestamps = require 'mongoose-times'
  findOrCreate = require 'mongoose-findorcreate'

  ChannelSchema = new Schema
    name: String
    users: [{ type: Schema.Types.ObjectId, ref: 'User' }]

  ChannelSchema.plugin timestamps, { created: "created_at", lastUpdated: "updated_at" }
  ChannelSchema.plugin findOrCreate

  ChannelSchema.methods.addUser = (user, callback) ->
    @users.push user._id
    @save (err, data) ->
      callback(err, data) if callback?

  ChannelSchema.methods.removeUser = (user, callback) ->
    @users = _.filter @users, (itrUser) ->
      String(itrUser) != String(user._id)
    @save (err, data) ->
      callback(err, data) if callback?

  ChannelSchema.statics.createChannel = (name, user, callback) ->
    channel = new ChannelModel
      name: name
      users: [ user._id ]
    channel.save (err, chnl) ->
      callback(err, chnl) if callback?

  ChannelSchema.statics.findChannelByName = (channelName, callback) ->
    ChannelModel
      .findOne
        name: channelName
      .exec (err, channel) ->
        callback(err, channel)

  ChannelSchema.statics.findChannelsByJoinedUser = (user, callback) ->
    ChannelModel
      .find
        users: user._id
      .exec (err, channels) ->
        callback(err, channels)

  ChannelModel = mongoose.model('Channel', ChannelSchema)
  ChannelModel
