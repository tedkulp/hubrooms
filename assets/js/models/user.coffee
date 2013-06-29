define ->
  Hubrooms.module 'Models', (module, App, Backbone, Marionette, $, _) ->
    class module.User extends Backbone.Model
      idAttribute: "_id"
      isPresent: ->
        @get('present')
