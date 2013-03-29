mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
timestamps = require 'mongoose-times'
findOrCreate = require 'mongoose-findorcreate'

ChannelSchema = new Schema
  name: String
  users: [{ type: Schema.Types.ObjectId, ref: 'User' }]

UserSchema.plugin timestamps, { created: "created_at", lastUpdated: "updated_at" }
UserSchema.plugin findOrCreate

module.exports = mongoose.model('User', UserSchema)
