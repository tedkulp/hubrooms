Hubrooms = new Backbone.Marionette.Application()
Socket = io.connect()

# Hubrooms.addRegions
#   unseen     : '#tab1'
#   unfriended : '#tab2'

Hubrooms.module 'Router', (module, App, Backbone, Marionette, $, _) ->
  class module.Router extends Marionette.AppRouter
    appRoutes:
      '' : 'index'

  class module.Controller
    constructor: ->
      #setup collections

    start: ->
      #setup views
      #fill initial collections
      #assign them to regions

    index: ->

  module.addInitializer ->
    controller = new module.Controller()
    router = new module.Router
      controller: controller

    controller.start()

    App.controller = controller
    App.router = router

Hubrooms.on 'initialize:after', ->
  Backbone.history.start()

  # Let the server know we're here
  Socket.emit('ready')

  window.Hubrooms = Hubrooms
  window.Socket = Socket

# Move me to the main chat page
$ ->
  Hubrooms.start()
