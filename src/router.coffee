DeployStateController = require './controllers/deploy-state-controller'

class Router
  constructor: ({@deployStateService}) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  route: (app) =>
    deployStateController = new DeployStateController {@deployStateService}

    app.route '/deployments/:owner/:repo'
      .get deployStateController.listDeployments

    app.route '/deployments/:owner/:repo/:tag'
      .get deployStateController.getDeployment
      .post deployStateController.createDeployment

    app.put '/deployments/:owner/:repo/:tag/build/:state/passed', deployStateController.update 'build', true
    app.put '/deployments/:owner/:repo/:tag/build/:state/failed', deployStateController.update 'build', false

    app.put '/deployments/:owner/:repo/:tag/cluster/:state/passed', deployStateController.update 'cluster', true
    app.put '/deployments/:owner/:repo/:tag/cluster/:state/failed', deployStateController.update 'cluster', false

    app.route '/webhooks'
      .post deployStateController.registerWebhook
      .delete deployStateController.deleteWebhook

    app.post '/deployments/quay.io', deployStateController.updateFromQuay
    app.post '/deployments/travis-ci', deployStateController.updateFromTravis

    app.get '/authorize', (request, response) => response.sendStatus(204)

module.exports = Router
