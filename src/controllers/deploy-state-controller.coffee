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
    { date } = request.query
    @deployStateService.createDeployment { owner, repo, tag, date }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  update: ({ passing, key }) =>
    return (request, response) =>
      { owner, repo, tag, state } = request.params
      { date } = request.query
      options = { owner, repo, tag, key: "#{key}.#{state}", passing, date }
      @deployStateService.update options, (error, code) =>
        return response.sendError error if error?
        response.sendStatus code

  updateFromQuay: (request, response) =>
    { docker_url, repository, tag } = request.body
    { date } = request.query
    @deployStateService.updateFromQuay { docker_url, repository, tag, date }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  listDeployments: (request, response) =>
    { owner, repo } = request.params
    @deployStateService.listDeployments { owner, repo }, (error, deployments) =>
      return response.sendError error if error?
      response.status(200).send { deployments }

  registerWebhook: (request, response) =>
    { url, token } = request.body
    return response.sendStatus(422) unless url?
    return response.sendStatus(422) unless token?
    @deployStateService.registerWebhook { url, token }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  deleteWebhook: (request, response) =>
    { url } = request.body
    return response.sendStatus(422) unless url?
    @deployStateService.deleteWebhook { url }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

module.exports = DeployStateController
