class DeployStateController
  constructor: ({@deployStateService}) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  hello: (request, response) =>
    {hasError} = request.query
    @deployStateService.doHello {hasError}, (error) =>
      return response.sendError(error) if error?
      response.sendStatus(200)

module.exports = DeployStateController
