Hubrooms = new Backbone.Marionette.Application()
Socket = io.connect()

Hubrooms.addRegions
  channelNav : '#channel_nav_area'
  messages   : '#messages'
  userlist   : '#userlist'

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
  class module.ChannelNavItem extends Marionette.ItemView
    template: '#channel-nav-item'
    tagName: 'li'
    className: 'channelNavItem'
    events:
      'click a' : 'clickChannel'

    initialize: ->
      @listenTo(App.vent, 'channel:changed', @determineActive, @)

    clickChannel: (e) ->
      e.preventDefault()
      App.router.navigate @model.get('name'),
        trigger: true

    onRender: ->
      @determineActive()

    determineActive: ->
      $(@el).toggleClass('active', Backbone.history.fragment == @model.get('name'))

  class module.ChannelNav extends Marionette.CollectionView
    itemView: module.ChannelNavItem
    tagName: 'ul'
    className: 'nav nav-tabs'

Hubrooms.module 'Router', (module, App, Backbone, Marionette, $, _) ->
  class module.Router extends Marionette.AppRouter
    appRoutes:
      ':username/:channel' : 'chat'

  class module.Controller
    constructor: ->
      @channels = new App.Models.Channels()

    start: ->
      @setupChannelNav()

    setupChannelNav: ->
      channelNav = new App.Views.ChannelNav
        collection: @channels
      App.channelNav.show channelNav

      @channels.fetch()

    chat: ->
      App.vent.trigger('channel:changed', Backbone.history.fragment)
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
