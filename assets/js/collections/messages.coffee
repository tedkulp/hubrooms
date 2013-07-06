define ['models/message'], (modelModule) ->
  Hubrooms.module 'Models', (module, App, Backbone, Marionette, $, _) ->
    class module.Messages extends Backbone.Collection
      model: modelModule.Message
      url: '/messages'
      page: 0
      hasMore: true
      prepend: false
      channelId: ''

      comparator: (message) ->
        message.get('_id')

      parse: (attrs, options) ->
        @hasMore = attrs.total > @length + attrs.results.length
        attrs = attrs.results
        attrs

      nextPage: ->
        if @hasMore
          @page++
          if @page > 1
            @prepend = true
            return @fetch
              add: true
              remove: false
              data:
                channel_id: @channelId
                start: (@page - 1) * 100
                no_reverse: true
          else
            @prepend = false
            return @fetch
              data:
                channel_id: @channelId
                start: (@page - 1) * 100
