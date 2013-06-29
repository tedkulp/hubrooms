define ->
  Hubrooms.module 'Models', (module, App, Backbone, Marionette, $, _) ->
    class module.Channel extends Backbone.Model
      idAttribute: "_id"
      isCurrent: ->
        Backbone.history.fragment == @get('name')
