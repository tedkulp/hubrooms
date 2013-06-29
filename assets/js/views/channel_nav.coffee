define ['views/channel_nav_item'], (channelNavItem) ->
  Hubrooms.module 'Views', (module, App, Backbone, Marionette, $, _) ->
    class module.ChannelNav extends Marionette.CollectionView
      itemView: channelNavItem.ChannelNavItem
      tagName: 'ul'
      className: 'nav nav-tabs'
