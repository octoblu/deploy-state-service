class DeployStateController
  constructor: ({@deployStateService}) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  getDeployment: (request, response) =>
    { service, tag } = request.params
    @deployStateService.getDeployment { service, tag }, (error, state) =>
      return response.sendError error if error?
      response.status(200).send { service, tag, state }

module.exports = DeployStateController
