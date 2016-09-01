basicauth             = require 'basicauth-middleware'
TravisAuth            = require './middlewares/travisauth-middleware'
DeployStateController = require './controllers/deploy-state-controller'

class Router
  constructor: ({ @deployStateService, @username, @password, @travisTokenPro, @travisTokenOrg }) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?
    throw new Error 'Missing travisTokenPro' unless @travisTokenPro?
    throw new Error 'Missing travisTokenOrg' unless @travisTokenOrg?
    throw new Error 'Missing username' unless @username?
    throw new Error 'Missing password' unless @password?

  route: (app) =>
    travisAuth = new TravisAuth { @travisTokenPro, @travisTokenOrg }
    deployStateController = new DeployStateController {@deployStateService}

    app.use (request) =>
      if request.path == '/deployments/travis-ci'
        return travisAuth.auth() arguments...

      return basicauth(@username, @password) arguments...

    baseRoute = '/deployments/:owner/:repo'
    app.route baseRoute
      .get deployStateController.listDeployments

    app.route "#{baseRoute}/:tag"
      .get deployStateController.getDeployment
      .post deployStateController.createDeployment

    app.put "#{baseRoute}/:tag/build/:state/passed", deployStateController.upsertDeployment 'build', true
    app.put "#{baseRoute}/:tag/build/:state/failed", deployStateController.upsertDeployment 'build', false

    app.put "#{baseRoute}/:tag/cluster/:state/passed", deployStateController.upsertDeployment 'cluster', true
    app.put "#{baseRoute}/:tag/cluster/:state/failed", deployStateController.upsertDeployment 'cluster', false

    app.route '/webhooks'
      .post deployStateController.registerWebhook
      .delete deployStateController.deleteWebhook

    app.post '/deployments/quay.io', deployStateController.updateFromQuay
    app.post '/deployments/travis-ci', deployStateController.updateFromTravis

    app.get '/authorize', (request, response) => response.sendStatus(204)

module.exports = Router
