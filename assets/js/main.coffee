# Example main.coffee file in /assets/js folder

requirePaths =
  paths:
    require_text: '//cdnjs.cloudflare.com/ajax/libs/require-text/2.0.5/text'
    jquery: '//ajax.googleapis.com/ajax/libs/jquery/1/jquery.min'
    jquery_ui: '//ajax.googleapis.com/ajax/libs/jqueryui/1/jquery-ui.min'
    underscore: '//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.4.4/underscore-min'
    underscore_string: '//cdnjs.cloudflare.com/ajax/libs/underscore.string/2.3.0/underscore.string.min'
    backbone: '//cdnjs.cloudflare.com/ajax/libs/backbone.js/1.0.0/backbone-min'
    moment: '//cdnjs.cloudflare.com/ajax/libs/moment.js/2.0.0/moment.min'
    socket_io: '/socket.io/socket.io'
    bootstrap: '/js/bootstrap.min'
    marionette: '/js/backbone.marionette.min'
    extensions: '/js/jquery_extensions'
    emoji: '/js/emoji'

if jsPaths
  for own key, value of jsPaths
    # Fix up the lib references
    key = key.slice 4 if key.slice(0, 4) == "lib/"
    requirePaths.paths[key] = value 

require.config
  paths: requirePaths.paths
  waitSeconds: 15
  shim:
    jquery:
      exports: "$"
    jquery_ui:
      deps: ['jquery']
    jquery_extensions:
      deps: ['jquery']
    bootstrap:
      deps: ['jquery']
    underscore:
      exports: "_"
    backbone:
      deps: ["underscore", "jquery"]
      exports: "Backbone"
    marionette:
      deps: ["underscore", "jquery", "backbone"]
      exports: "Backbone.Marionette"

require ['app'], (App) ->
  require ['router', 'initialization'], (router, initialization) ->
    App.start()
