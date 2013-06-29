define ->
  Hubrooms.module 'Models', (module, App, Backbone, Marionette, $, _) ->
    class module.Message extends Backbone.Model
      url: '/messages'
      idAttribute: "_id"
      defaults: ->
        msg: null
        channel_id: null
        login: null
        name: null
        created_at: new Date()
        updated_at: new Date()

      validate: (attrs) ->
        if !attrs or attrs.msg == ''
          'No Msg Given'
