DeployStateController = require './controllers/deploy-state-controller'

class Router
  constructor: ({@deployStateService}) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  route: (app) =>
    deployStateController = new DeployStateController {@deployStateService}

    app.get    '/deployments/:owner/:repo', deployStateController.listDeployments
    app.get    '/deployments/:owner/:repo/:tag', deployStateController.getDeployment
    app.post   '/deployments/:owner/:repo/:tag', deployStateController.createDeployment
    app.put    '/deployments/:owner/:repo/:tag/build/:state/passed', deployStateController.update {
      key: 'build',
      passing: true
    }
    app.put    '/deployments/:owner/:repo/:tag/build/:state/failed', deployStateController.update {
      key: 'build',
      passing: false
    }
    app.put    '/deployments/:owner/:repo/:tag/cluster/:state/passed', deployStateController.update {
      key: 'cluster',
      passing: true
    }
    app.put    '/deployments/:owner/:repo/:tag/cluster/:state/failed', deployStateController.update {
      key: 'cluster',
      passing: false
    }
    app.post   '/webhooks', deployStateController.registerWebhook
    app.delete '/webhooks', deployStateController.deleteWebhook
    app.get    '/authorize', (request, response) => response.sendStatus(204)

module.exports = Router
