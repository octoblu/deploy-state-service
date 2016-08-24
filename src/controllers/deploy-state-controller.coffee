class DeployStateController
  constructor: ({@deployStateService}) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  getDeployment: (request, response) =>
    { owner, repo, tag } = request.params
    @deployStateService.getDeployment { owner, repo, tag }, (error, deployment) =>
      return response.sendError error if error?
      response.status(200).send deployment

  createDeployment: (request, response) =>
    { owner, repo, tag } = request.params
    @deployStateService.createDeployment { owner, repo, tag }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  updateBuildPassed: (request, response) =>
    { owner, repo, tag, state } = request.params
    options = {
      owner,
      repo,
      tag,
      key: "build.#{state}",
      passing: true
    }
    @deployStateService.update options, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  updateBuildFailed: (request, response) =>
    { owner, repo, tag, state } = request.params
    options = {
      owner,
      repo,
      tag,
      key: "build.#{state}",
      passing: false
    }
    @deployStateService.update options, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  updateClusterPassed: (request, response) =>
    { owner, repo, tag, state } = request.params
    options = {
      owner,
      repo,
      tag,
      key: "cluster.#{state}",
      passing: true
    }
    @deployStateService.update options, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  updateClusterFailed: (request, response) =>
    { owner, repo, tag, state } = request.params
    options = {
      owner,
      repo,
      tag,
      key: "cluster.#{state}",
      passing: false
    }
    @deployStateService.update options, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  listDeployments: (request, response) =>
    { owner, repo } = request.params
    @deployStateService.listDeployments { owner, repo }, (error, deployments) =>
      return response.sendError error if error?
      response.status(200).send { deployments }

module.exports = DeployStateController
