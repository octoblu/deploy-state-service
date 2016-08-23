DeployStateController = require './controllers/deploy-state-controller'

class Router
  constructor: ({@deployStateService}) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  route: (app) =>
    deployStateController = new DeployStateController {@deployStateService}

    app.get '/deployments/:owner/:repo/:tag', deployStateController.getDeployment
    app.get '/status/travis/:owner/:repo/:tag', deployStateController.getTravisStatus
    app.get '/authorize', (request, response) => response.sendStatus(204)

module.exports = Router
