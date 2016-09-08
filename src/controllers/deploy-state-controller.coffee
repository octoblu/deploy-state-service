_     = require 'lodash'
debug = require('debug')('deploy-state-service:controller')

class DeployStateController
  constructor: ({ @deployStateService }) ->
    throw new Error 'Missing deployStateService' unless @deployStateService?

  getDeployment: (request, response) =>
    { owner, repo, tag } = request.params
    debug 'getDeployment', { owner, repo, tag }
    @deployStateService.getDeployment { owner, repo, tag }, (error, deployment, code) =>
      return response.sendError error if error?
      return response.sendStatus code if code?
      response.status(200).send deployment

  createDeployment: (request, response) =>
    { owner, repo, tag } = request.params
    { date } = request.query
    debug 'createDeployment', { owner, repo, tag }
    @deployStateService.createDeployment { owner, repo, tag, date }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  upsertDeployment: (key, passing) =>
    return (request, response) =>
      { owner, repo, tag, state } = request.params
      { date } = request.query
      options = { owner, repo, tag, key: "#{key}.#{state}", passing, date }
      debug 'upsertDeployment', options
      @deployStateService.upsertDeployment options, (error) =>
        return response.sendError error if error?
        response.sendStatus 204

  updateFromQuay: (request, response) =>
    { docker_url, name, namespace, updated_tags } = request.body
    { date } = request.query
    tag = _.first(updated_tags)
    options = {
      dockerUrl: "#{docker_url}:#{tag}",
      key: 'build.docker',
      passing: true,
      owner: namespace,
      repo: name,
      tag,
      date
    }
    debug 'updateFromQuay', options
    @deployStateService.upsertDeployment options, (error) =>
      return response.sendError error if error?
      response.sendStatus 201

  updateFromTravis: (request, response) =>
    try
      payload = JSON.parse request.body?.payload
    catch error
      response.sendError error
      return
    { repository, status, result, branch } = payload
    return response.sendStatus(422) unless /^v\d+/.test branch
    { date } = request.query
    options = {
      key: 'build.travis-ci',
      passing: status == 0 || status == '0',
      owner: repository.owner_name,
      repo: repository.name,
      tag: branch,
      date
    }
    debug 'updateFromTravis', { status, result }
    debug 'updateFromTravis', options
    @deployStateService.upsertDeployment options, (error) =>
      return response.sendError error if error?
      response.sendStatus 204

  listDeployments: (request, response) =>
    { owner, repo } = request.params
    debug 'listDeployments', { owner, repo }
    @deployStateService.listDeployments { owner, repo }, (error, deployments) =>
      return response.sendError error if error?
      response.status(200).send { deployments }

  registerWebhook: (request, response) =>
    { url, auth, events } = request.body
    debug 'registerWebhook', { url, auth, events }
    return response.sendStatus(422) unless url?
    @deployStateService.registerWebhook { url, auth, events }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

  deleteWebhook: (request, response) =>
    { url } = request.body
    debug 'delete webhook', { url }
    return response.sendStatus(422) unless url?
    @deployStateService.deleteWebhook { url }, (error, code) =>
      return response.sendError error if error?
      response.sendStatus code

module.exports = DeployStateController
