define ->
  Hubrooms.module 'Views', (module, App, Backbone, Marionette, $, _) ->
    class module.ChannelUserItem extends Marionette.ItemView
      template: '#channel-user-item'
      tagName: 'li'
      className: 'channelUserItem'
      initialize: ->
        @listenTo(@model, 'change', @render)
      onRender: ->
        $(@el).toggleClass('inactive', !@model.isPresent())
