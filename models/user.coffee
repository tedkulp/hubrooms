mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectI
timestamps = require 'mongoose-times'
findOrCreate = require 'mongoose-findorcreate'

UserSchema = new Schema
  login: String
  external_id: Number
  name: String
  location: String
  email: String
  url: String

UserSchema.plugin timestamps, { created: "created_at", lastUpdated: "updated_at" }
UserSchema.plugin findOrCreate

module.exports = mongoose.model('User', UserSchema)
