define ['models/message'], (modelModule) ->
  Hubrooms.module 'Models', (module, App, Backbone, Marionette, $, _) ->
    class module.Messages extends Backbone.Collection
      model: modelModule.Message
      url: '/messages'
      page: 1
      channelId: ''
