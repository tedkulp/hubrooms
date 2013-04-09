mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
timestamps = require 'mongoose-times'
findOrCreate = require 'mongoose-findorcreate'

ChannelSchema = new Schema
  name: String
  users: [{ type: Schema.Types.ObjectId, ref: 'User' }]

ChannelSchema.plugin timestamps, { created: "created_at", lastUpdated: "updated_at" }
ChannelSchema.plugin findOrCreate

ChannelModel = mongoose.model('Channel', ChannelSchema)

ChannelModel.createChannel = (name, user, callback) ->
  channel = new ChannelModel
    name: name
    users: [ user._id ]
  channel.save (err, chnl) ->
    callback(err, chnl) if callback?

module.exports = ChannelModel
