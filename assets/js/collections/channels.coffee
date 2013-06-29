define ['models/channel'], (modelModule) ->
  Hubrooms.module 'Models', (module, App, Backbone, Marionette, $, _) ->
    class module.Channels extends Backbone.Collection
      model: modelModule.Channel
      url: '/channels'
      fetched: false

      findCurrent: ->
        _.find @models, (item) ->
          item.isCurrent()

      getCurrentChannel: ->
        dfd = $.Deferred()
        if @fetched
          dfd.resolve(@findCurrent())
        else
          @fetch().done =>
            dfd.resolve(@findCurrent())
        dfd

      sync: (method, model, options) ->
        promise = Backbone.sync(method, model, options)
        promise.done () =>
          # Just so we know we have *some* data
          @fetched = true
        promise
