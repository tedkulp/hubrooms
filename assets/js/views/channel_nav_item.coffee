define ['router'], (router) ->
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
        router.navigate @model.get('name'),
          trigger: true

      onRender: ->
        @determineActive()

      determineActive: ->
        $(@el).toggleClass('active', @model.isCurrent())
