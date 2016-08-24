DeployStateController = require './controllers/deploy-state-controller'

class Router
  constructor: ({@deployStateService}) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  route: (app) =>
    deployStateController = new DeployStateController {@deployStateService}

    app.get  '/deployments/:owner/:repo', deployStateController.listDeployments
    app.get  '/deployments/:owner/:repo/:tag', deployStateController.getDeployment
    app.post '/deployments/:owner/:repo/:tag', deployStateController.createDeployment
    app.put  '/deployments/:owner/:repo/:tag/build/:state/passed', deployStateController.updateBuildPassed
    app.put  '/deployments/:owner/:repo/:tag/build/:state/failed', deployStateController.updateBuildFailed
    app.put  '/deployments/:owner/:repo/:tag/cluster/:state/passed', deployStateController.updateClusterPassed
    app.put  '/deployments/:owner/:repo/:tag/cluster/:state/failed', deployStateController.updateClusterFailed
    app.get  '/authorize', (request, response) => response.sendStatus(204)

module.exports = Router
