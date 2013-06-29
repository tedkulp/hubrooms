define ['controller'], (controller) ->
  class Router extends Marionette.AppRouter
    appRoutes:
      ':username/:channel' : 'chat'

  router = new Router
    controller: controller

  controller.start()

  router
