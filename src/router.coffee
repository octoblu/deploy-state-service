DeployStateController = require './controllers/deploy-state-controller'

class Router
  constructor: ({@deployStateService}) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  route: (app) =>
    deployStateController = new DeployStateController {@deployStateService}

    app.get '/deployments/:service/:tag', deployStateController.getDeployment

module.exports = Router
