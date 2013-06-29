define ['views/channel_user_item'], (channelUserItem) ->
  Hubrooms.module 'Views', (module, App, Backbone, Marionette, $, _) ->
    class module.UserList extends Marionette.CollectionView
      itemView: module.ChannelUserItem
      tagName: 'ul'
      className: 'nav nav-list'
