define ['app', 'controller'], (App, controller) ->
  class Router extends Marionette.AppRouter
    appRoutes:
      ':username/:channel' : 'chat'

  router = App.router = new Router
    controller: controller

  controller.start()

  router
