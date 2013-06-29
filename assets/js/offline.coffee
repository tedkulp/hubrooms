define ['jquery_ui'], (jquery_ui) ->
  return $("<div></div>")
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
