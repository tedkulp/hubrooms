mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
timestamps = require 'mongoose-times'
findOrCreate = require 'mongoose-findorcreate'

MessageSchema = new Schema
  name: String
  login: String
  user_id: Schema.Types.ObjectId
  channel_id: Schema.Types.ObjectId
  msg: String

MessageSchema.plugin timestamps, { created: "created_at", lastUpdated: "updated_at" }
MessageSchema.plugin findOrCreate

module.exports = mongoose.model('Message', MessageSchema)
