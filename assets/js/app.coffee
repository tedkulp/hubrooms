Hubrooms = new Backbone.Marionette.Application()
Socket = io.connect()

# Hubrooms.addRegions
#   unseen     : '#tab1'
#   unfriended : '#tab2'

Hubrooms.module 'Models', (module, App, Backbone, Marionette, $, _) ->
  class module.Channel extends Backbone.Model
    name: 'channel'

  class module.Channels extends Backbone.Collection
    model: module.Channel
    url: '/channels'

  class module.Message extends Backbone.Model
    name: 'message'

  class module.Messages extends Backbone.Collection
    model: module.Message
    url: '/messages'

Hubrooms.module 'Views', (module, App, Backbone, Marionette, $, _) ->

Hubrooms.module 'Router', (module, App, Backbone, Marionette, $, _) ->
  class module.Router extends Marionette.AppRouter
    appRoutes:
      ':username/:channel' : 'chat'

  class module.Controller
    constructor: ->
      #setup collections

    start: ->
      #setup views
      #fill initial collections
      #assign them to regions

    chat: ->
      console.log 'here'

  module.addInitializer ->
    controller = new module.Controller()
    router = new module.Router
      controller: controller

    controller.start()

    App.controller = controller
    App.router = router

Hubrooms.on 'initialize:after', ->
  Backbone.history.start({pushState: true})

  # Let the server know we're here
  Socket.emit('ready')

  window.Hubrooms = Hubrooms
  window.Socket = Socket

# Move me to the main chat page
$ ->
  Hubrooms.start()
