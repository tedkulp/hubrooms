define ['jquery_ui'], (bootstrap) ->
  Hubrooms.module 'Views', (module, App, Backbone, Marionette, $, _) ->
    class module.SendMessageArea extends Marionette.ItemView
      template: '#send-message-area-input'
      events:
        'click #sendmsgbutton' : 'sendMessage'
        'submit #sendmsg' : 'sendMessage'
      ui:
        form: '#sendmsg'
        inputBox: '#sendmsginput'
        submitBtn: '#sendmsgbutton'

      onRender: ->
        currentWordRange = null
        $(@ui.inputBox).autocomplete
          source: (req, res) ->
            res _.map App.controller.users.getLikeLoginNames(req.term), (item) ->
              "@" + item.get('login')
          autoFocus: true
          disabled: true
          position:
            my: 'left bottom'
            at: 'left top'
          select: (e, ui) =>
            $(@ui.inputBox).val(replaceRange($(@ui.inputBox).val(), currentWordRange.start, currentWordRange.end, ui.item.value + ": "))
            false
          focus: (e, ui) ->
            false
          close: (e, ui) =>
            $(@ui.inputBox).autocomplete("disable", true)
            $(@ui.inputBox).focus()
        .bind 'keydown', (e) =>
          if e.keyCode == 9
            if e.preventDefault
              e.preventDefault()
            currentWordRange = $(@ui.inputBox).getCurrentWordRange()
            $(@ui.inputBox).autocomplete("enable", true)
            $(@ui.inputBox).autocomplete("search", currentWordRange.value)
            false
          else
            true

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
