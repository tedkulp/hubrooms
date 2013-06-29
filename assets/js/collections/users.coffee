define ['models/user'], (modelModule) ->
  Hubrooms.module 'Models', (module, App, Backbone, Marionette, $, _) ->
    class module.Users extends Backbone.Collection
      model: modelModule.User
      url: '/channel_users'
      channelId: ''

      getLikeLoginNames: (loginText) ->
        @models.filter (data) ->
          ('@' + data.get('login').toLowerCase()).indexOf(loginText.toLowerCase()) == 0
