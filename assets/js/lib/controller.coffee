define ['app', 'collections/channels', 'collections/messages', 'collections/users', 'views/messages_view', 'views/send_message_area'], (App, channels, messages, users, messages_view, send_message_area) ->
  class Controller
    constructor: ->
      @channels = new channels.Channels()
      @messages = new messages.Messages()
      @users = new users.Users()

    start: ->
      @setupChannelNav()
      @setupSendMessageArea()
      @setupUserList()

      messagesView = new messages_view.MessagesView
        collection: @messages
      App.messages.show messagesView

    setupSendMessageArea: ->
      sendMessageArea = new send_message_area.SendMessageArea
      App.sendMessageArea.show sendMessageArea

    setupChannelNav: ->
      require ['views/channel_nav'], (channel_nav) =>
        channelNav = new channel_nav.ChannelNav
          collection: @channels
        App.channelNav.show channelNav

    setupUserList: ->
      require ['views/user_list'], (user_list) =>
        userList = new user_list.UserList
          collection: @users
        App.userList.show userList

      # No need to fetch -- @chat will do it in the getCurrentChannel call

    chat: ->
      @channels.getCurrentChannel().done (currentChannel) =>
        @messages.fetch
          data:
            channel_id: currentChannel.get('_id')
        @users.fetch
          data:
            channel_id: currentChannel.get('_id')

      App.vent.trigger('channel:changed', Backbone.history.fragment)

  App.controller = new Controller()

  App.controller
