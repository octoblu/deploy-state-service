class DeployStateController
  constructor: ({@deployStateService}) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  getDeployment: (request, response) =>
    { owner, repo, tag } = request.params
    @deployStateService.getDeployment { owner, repo, tag }, (error, deployment) =>
      return response.sendError error if error?
      response.status(200).send deployment

module.exports = DeployStateController
