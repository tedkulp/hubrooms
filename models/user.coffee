define ['cs!lib/mongoose'], (mongoose) ->
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId
  timestamps = require 'mongoose-times'
  findOrCreate = require 'mongoose-findorcreate'

  UserSchema = new Schema
    login: String
    external_id: Number
    name: String
    location: String
    email: String
    url: String
    access_token: String
    refresh_token: String
    api_key: String
    channels: [{ type: Schema.Types.ObjectId, ref: 'Channel' }]

  UserSchema.plugin timestamps, { created: "created_at", lastUpdated: "updated_at" }
  UserSchema.plugin findOrCreate

  mongoose.model('User', UserSchema)
