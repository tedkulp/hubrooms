_ = require('underscore')

define ['views/message_item', 'jquery_extensions'], (messageItem, jqueryExtensions) ->
  Hubrooms.module 'Views', (module, App, Backbone, Marionette, $, _) ->
    class module.MessagesView extends Marionette.CompositeView
      template: _.template('<table class="table table-striped table-condensed" id="messages-table"></table>')
      itemView: messageItem.MessageItem
      itemViewContainer: '#messages-table'
      className: 'messages'
      ui:
        table: '#messages-table'

      onRender: ->
        @$el.off 'scroll'
        @$el.on 'scroll', (e) =>
          if @$el[0].scrollHeight > @$el.height()
            if @$el.scrollTop() == 0
              scrollTo = @$('tr:first')
              promise = @collection.nextPage()
              if promise
                promise.done =>
                  @$el.scrollTop scrollTo.offset().top - @$el.offset().top + @$el.scrollTop()

      appendHtml: (collectionView, itemView, index) ->
        if @collection.prepend
          @ui.table.prepend(itemView.el)
        else
          @ui.table.append(itemView.el)
