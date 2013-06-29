define ['views/message_item'], (messageItem) ->
  Hubrooms.module 'Views', (module, App, Backbone, Marionette, $, _) ->
    class module.MessagesView extends Marionette.CollectionView
      itemView: messageItem.MessageItem
      tagName: 'table'
      className: 'table table-striped table-condensed'
      ui:
        messages : '#messages'

      onBeforeItemAdded: ->
        @scrollDown = $(@ui.messages).scrollTop() == ($(@ui.messages)[0].scrollHeight - $(@ui.messages)[0].offsetHeight)

      onAfterItemAdded: ->
        if @scrollDown
          $(@ui.messages).scrollTop($(@ui.messages)[0].scrollHeight)
        @scrollDown = false
