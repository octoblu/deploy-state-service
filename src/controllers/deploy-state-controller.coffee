class DeployStateController
  constructor: ({@deployStateService}) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  getDeployment: (request, response) =>
    { owner, repo, tag } = request.params
    @deployStateService.getDeployment { owner, repo, tag }, (error, deployment, code) =>
      return response.sendError error if error?
      return response.sendStatus code if code?
      response.status(200).send deployment

  createDeployment: (request, response) =>
    { owner, repo, tag } = request.params
    { date } = request.query
    @deployStateService.createDeployment { owner, repo, tag, date }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  upsertDeployment: (key, passing) =>
    return (request, response) =>
      { owner, repo, tag, state } = request.params
      { date } = request.query
      options = { owner, repo, tag, key: "#{key}.#{state}", passing, date }
      @deployStateService.upsertDeployment options, (error) =>
        return response.sendError error if error?
        response.sendStatus 204

  updateFromQuay: (request, response) =>
    { docker_url, repository, tag } = request.body
    { date } = request.query
    [ owner, repo ] = repository.split '/'
    options = {
      dockerUrl: docker_url,
      key: 'build.docker',
      passing: true,
      owner,
      repo,
      tag,
      date
    }
    @deployStateService.upsertDeployment options, (error) =>
      return response.sendError error if error?
      response.sendStatus 201

  updateFromTravis: (request, response) =>
    { repository, status, branch } = request.body?.payload
    return response.sendStatus(422) unless /^v\d+/.test branch
    { date } = request.query
    options = {
      key: 'build.travis-ci',
      passing: status == 1 || status == '1',
      owner: repository.owner_name,
      repo: repository.name,
      tag: branch,
      date
    }
    @deployStateService.upsertDeployment options, (error) =>
      return response.sendError error if error?
      response.sendStatus 204

  listDeployments: (request, response) =>
    { owner, repo } = request.params
    @deployStateService.listDeployments { owner, repo }, (error, deployments) =>
      return response.sendError error if error?
      response.status(200).send { deployments }

  registerWebhook: (request, response) =>
    { url, auth, events } = request.body
    return response.sendStatus(422) unless url?
    @deployStateService.registerWebhook { url, auth, events }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  deleteWebhook: (request, response) =>
    { url } = request.body
    return response.sendStatus(422) unless url?
    @deployStateService.deleteWebhook { url }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

module.exports = DeployStateController
