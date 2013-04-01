Hubrooms = new Backbone.Marionette.Application()
Socket = io.connect()

Hubrooms.addRegions
  channelNav      : '#channel_nav_area'
  messages        : '#messages'
  userlist        : '#userlist'
  sendMessageArea : '#send_message_area'

Hubrooms.module 'Models', (module, App, Backbone, Marionette, $, _) ->
  class module.Channel extends Backbone.Model
    isCurrent: ->
      Backbone.history.fragment == @get('name')

  class module.Channels extends Backbone.Collection
    model: module.Channel
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

  class module.Message extends Backbone.Model
    url: '/messages'
    defaults:
      msg: null
      channel_id: null
      login: null
      name: null
      created_at: new Date()
      updated_at: new Date()

  validate: (attrs) ->
    if !attrs or attrs.msg == ''
      'No Msg Given'

  class module.Messages extends Backbone.Collection
    model: module.Message
    url: '/messages'
    page: 1
    channelId: ''

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
      $(@el).toggleClass('active', @model.isCurrent())

  class module.ChannelNav extends Marionette.CollectionView
    itemView: module.ChannelNavItem
    tagName: 'ul'
    className: 'nav nav-tabs'

  class module.SendMessageArea extends Marionette.ItemView
    template: '#send-message-area-input'
    events:
      'click #sendmsgbutton' : 'sendMessage'
      'submit #sendmsg' : 'sendMessage'
    ui:
      form: '#sendmsg'
      inputBox: '#sendmsginput'
      submitBtn: '#sendmsgbutton'

    getCurrentChannel: ->
      App.controller.channels.getCurrentChannel()

    sendMessage: (e) ->
      e.preventDefault()
      e.stopPropagation()

      model = new App.Models.Message()
      model.set('msg', @ui.inputBox.val())

      @getCurrentChannel().done (currentChannel) =>
        if model.isValid() and currentChannel
          model.set('channel_id', currentChannel.get('_id'))
          model.save
            success: (message) =>
              console.log message
            error: (message, jqXHR) =>
              console.log message
              console.log jqXHR

          @ui.inputBox.val('')

  class module.MessageItem extends Marionette.ItemView
    template: '#message-item'
    tagName: "tr"
    ui:
      time    : '.message_time'
      message : '.message'
      name    : '.message_name'

    imgRegex: /(https?:\/\/\S+\.(gif|jpe?g|png))(?:\?[A-Za-z0-9_\-\=]+)?/ig
    linkRegex: /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
    emojiRegex: /\:([A-Za-z0-9\-_]+)\:/ig
    youtubeRegex: /http:\/\/(?:www\.)?youtube.com\/watch\?(?=.*v=([\w\-]+))(?:[^><\s]+)?/ig
    emoticonsRegex: null
    emoticons:
      ':-)' : '/assets/emojis/smile.png'
      ':)'  : '/assets/emojis/smile.png'
      ':D'  : '/assets/emojis/tongue.png'
      ':-|' : '/assets/emojis/pensive.png'
      ':-(' : '/assets/emojis/cry.png'
      ':('  : '/assets/emojis/cry.png'
      ';-)' : '/assets/emojis/wink.png'
      ';)'  : '/assets/emojis/wink.png'

    initialize: (options) ->
      # TODO: Find way to not store this in a global for caching
      if App.emoticonsRegex
        @emoticonsRegex = App.emoticonsRegex
      else
        patterns = []
        metachars = /[[\]{}()*+?.\\|^$\-,&#\s]/g

        for key,value of @emoticons
          if @emoticons.hasOwnProperty(key)
            patterns.push '(' + key.replace(metachars, "\\$&") + ')'

        @emoticonsRegex = new RegExp(patterns.join('|'), 'g')
        App.emoticonsRegex = @emoticonsRegex

    onRender: ->
      @ui.time.html(moment(@ui.time.data('ts')).format('D-MMM h:mma'))
      @ui.message.html(@replaceMessageText(@ui.message.html()))

    replaceMessageText: (resp) ->
      if @containsLogin(resp, window.user_login)
        $(@el).addClass('highlightedRow')

      imgResp = @replaceURLWithImageTags(resp)
      if imgResp != resp
        resp = imgResp
      else
        linkResp = @replaceURLWithHTMLLinks(resp)
        if linkResp != resp
          resp = linkResp

      resp = @replaceTextWithEmoticons(resp)
      resp = @replaceTextWithEmoji(resp)
      resp

    containsLogin: (text, login) ->
      text.indexOf(login) > -1

    replaceURLWithHTMLLinks: (text) ->
      text.replace @linkRegex, (match, m0) ->
        "<a href='#{m0}' target='_blank'>#{m0}</a>"

    replaceURLWithImageTags: (text) ->
      text.replace @imgRegex, (match, m0) ->
        "<a href='#{m0}' target='_blank'><img src='#{m0}' alt='' border='0' align='absmiddle' /></a>"

    replaceTextWithEmoticons: (text) ->
      text.replace @emoticonsRegex, (match) =>
        if typeof @emoticons[match] != 'undefined'
         "<img src='" + @emoticons[match] + "' height='20' width='20' align='absmiddle'/>"
        else
          match

    replaceTextWithEmoji: (text) =>
      text.replace @emojiRegex, (str, p1, offset, s) ->
        if App.emoji_map and App.emoji_map[p1]
          "<img src='" + App.emoji_map[p1] + "' height='20' width='20' align='absmiddle' />"
        else
          str

  class module.MessagesView extends Marionette.CollectionView
    itemView: module.MessageItem
    tagName: 'table'
    className: 'table table-striped table-condensed'

Hubrooms.module 'Router', (module, App, Backbone, Marionette, $, _) ->
  class module.Router extends Marionette.AppRouter
    appRoutes:
      ':username/:channel' : 'chat'

  class module.Controller
    constructor: ->
      @channels = new App.Models.Channels()
      @messages = new App.Models.Messages()

    start: ->
      @setupChannelNav()
      @setupSendMessageArea()

      messagesView = new App.Views.MessagesView
        collection: @messages
      App.messages.show messagesView

    setupSendMessageArea: ->
      sendMessageArea = new App.Views.SendMessageArea
      App.sendMessageArea.show sendMessageArea

    setupChannelNav: ->
      channelNav = new App.Views.ChannelNav
        collection: @channels
      App.channelNav.show channelNav

      # No need to fetch -- @chat will do it in the getCurrentChannel call

    chat: ->
      @channels.getCurrentChannel().done (currentChannel) =>
        @messages.fetch
          data:
            channel_id: currentChannel.get('_id')

      App.vent.trigger('channel:changed', Backbone.history.fragment)

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

  # Move me somewhere better
  Socket.on 'new-message', (data) ->
    message = new Hubrooms.Models.Message(data)
    if message
      currentChannel = Hubrooms.controller.channels.findCurrent()
      console.log currentChannel.get('_id'), message.get('channel_id')
      if currentChannel.get('_id') == message.get('channel_id')
        Hubrooms.controller.messages.add(message)
      else
        # Handle the highlighting if name is mentioned

  window.Hubrooms = Hubrooms
  window.Socket = Socket

# Move me to the main chat page
$ ->
  offline = $("<div></div>")
  .html("The connection has been disconnected! <br /> " +
    "Please go back online to use this service.")
  .dialog
    autoOpen: false,
    modal:    true,
    width:    330,
    resizable: false,
    closeOnEscape: false,
    title: "Connection",
    open: (event, ui) ->
      $(".ui-dialog-titlebar-close").hide()

  Socket.on 'connect', (data) ->
    offline.dialog("close")

  Socket.on 'disconnect', (data) ->
    offline.dialog("open")

  Hubrooms.start()
