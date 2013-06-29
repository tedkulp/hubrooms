define ['moment'], (moment) ->
  Hubrooms.module 'Views', (module, App, Backbone, Marionette, $, _) ->
    class module.MessageItem extends Marionette.ItemView
      template: '#message-item'
      tagName: "tr"
      ui:
        time    : '.message_time'
        message : '.message'
        name    : '.message_name'
      templateHelpers: =>
        view = @
        escapeMessage: ->
          resp = @msg
          resp = resp.replace(/\</g, "&lt;").replace(/\>/g, "&gt;").replace(/\n/g, '<br />')

          imgResp = view.replaceURLWithImageTags(resp)
          if imgResp != resp
            resp = imgResp
          else
            youtubeResp = view.replaceURLWithYoutubeEmbeds(resp)
            if youtubeResp != resp
              resp = youtubeResp
            else
              linkResp = view.replaceURLWithHTMLLinks(resp)
              if linkResp != resp
                resp = linkResp

          resp = view.replaceTextWithEmoticons(resp)
          resp = view.replaceTextWithEmoji(resp)
          resp

      imgRegex: /(https?:\/\/\S+\.(gif|jpe?g|png))(?:\?[A-Za-z0-9_\-\=\&]+)?/ig
      linkRegex: /(\b(https?|ftp|file):\/\/[-A-Z0-9+&@#\/%?=~_|!:,.;]*[-A-Z0-9+&@#\/%=~_|])/ig
      emojiRegex: /\:([A-Za-z0-9\-_]+)\:/ig
      youtubeRegex: /http:\/\/(?:www\.)?youtube.com\/watch\?(?=.*v=([\w\-]+))(?:[^><\s]+)?/ig
      emoticonsRegex: null
      emoticons:
        ':-)' : '/img/emojis/smile.png'
        ':)'  : '/img/emojis/smile.png'
        ':D'  : '/img/emojis/tongue.png'
        ':-|' : '/img/emojis/pensive.png'
        ':-(' : '/img/emojis/cry.png'
        ':('  : '/img/emojis/cry.png'
        ';-)' : '/img/emojis/wink.png'
        ';)'  : '/img/emojis/wink.png'

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
        # @ui.message.html(@replaceMessageText(@ui.message.html()))

        if @containsLogin(@ui.message.html(), window.user_login)
          $(@el).addClass('highlightedRow')

      containsLogin: (text, login) ->
        text.indexOf(login) > -1

      replaceURLWithHTMLLinks: (text) ->
        text.replace @linkRegex, (match, m0) ->
          "<a href='#{m0}' target='_blank'>#{m0}</a>"

      replaceURLWithImageTags: (text) ->
        text.replace @imgRegex, (match, m0) ->
          "<a href='#{m0}' target='_blank'><img src='#{m0}' alt='' border='0' align='absmiddle' /></a>"

      replaceURLWithYoutubeEmbeds: (text) ->
        text.replace @youtubeRegex, (match, m0) =>
          $(@el).css('min-height', '182px')
          "<iframe width='299' height='182' src='//www.youtube.com/embed/" + m0 + "?rel=0' frameborder='0' allowfullscreen></iframe>"

      replaceTextWithEmoticons: (text) ->
        text.replace @emoticonsRegex, (match) =>
          if typeof @emoticons[match] != 'undefined'
           "<img src='" + @emoticons[match] + "' height='20' width='20' align='absmiddle'/>"
          else
            match

      replaceTextWithEmoji: (text) =>
        text.replace @emojiRegex, (str, p1, offset, s) ->
          if window.emoji_map and window.emoji_map[p1]
            "<img src='" + window.emoji_map[p1] + "' height='20' width='20' align='absmiddle' />"
          else
            str

