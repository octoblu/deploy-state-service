_       = require 'lodash'
async   = require 'async'
moment  = require 'moment'
request = require 'request'

PROJECTION =
  _id:   false
  tag:   true
  owner: true
  repo:  true
  createdAt: true
  build: true
  cluster: true

class DeployStateService
  constructor: ({ database }) ->
    @deployments = database.collection 'deployments'
    @webhooks = database.collection 'webhooks'

  getDeployment: ({ owner, repo, tag }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback @_createError(404, 'Unable to find deployment') unless deployment?
      callback null, deployment

  createDeployment: ({ owner, repo, tag }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback null, 204 if deployment?
      record = {
        owner,
        repo,
        tag,
        build: {},
        cluster: {},
        createdAt: new Date()
      }
      @deployments.insert record, (error) =>
        return callback error if error?
        callback null, 201

  update: ({ owner, repo, tag, key, passing }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback null, 404 unless deployment?

      query = {}
      query["#{key}.passing"] = passing
      query["#{key}.createdAt"] = new Date() unless _.get deployment, "#{key}.createdAt"
      query["#{key}.updatedAt"] = new Date() if _.get deployment, "#{key}.createdAt"

      @deployments.update { owner, repo, tag }, { $set: query }, (error) =>
        return callback error if error?
        @_notifyAll { owner, repo, tag }, (error) =>
          return callback error if error?
          callback null, 204

  listDeployments: ({ owner, repo }, callback) =>
    @_findDeployments { owner, repo }, callback

  registerWebhook: ({ url }, callback) =>
    @webhooks.findOne { url }, (error, webhook) =>
      return callback error if error?
      return callback null, 204 if webhook?
      @webhooks.insert { url }, (error) =>
        return callback error if error?
        callback null, 201

  deleteWebhook: ({ url }, callback) =>
    @webhooks.findOne { url }, (error, webhook) =>
      return callback error if error?
      return callback null, 404 unless webhook?
      @webhooks.remove { url }, (error) =>
        return callback error if error?
        callback null, 204

  _notifyAll: ({ owner, repo, tag }, callback) =>
    @webhooks.find {}, (error, webhooks) =>
      return callback error if error?
      return callback null if _.isEmpty webhooks
      @_findDeployment { owner, repo, tag }, (error, deployment) =>
        return callback error if error?
        async.each webhooks, @_notify, callback

  _notify: ({ url }, callback) =>
    request.post url, (error, response) =>
      return callback error if error?
      return callback new Error 'Fatal error from webhook' if response.statusCode >= 500
      callback null

  _findDeployment: ({ owner, repo, tag }, callback) =>
    @deployments.findOne { owner, repo, tag }, PROJECTION, (error, deployment) =>
      return callback error if error?
      return callback null, null unless deployment?
      callback null, @_mapDeployment deployment

  _findDeployments: ({ owner, repo }, callback) =>
    @deployments.find { owner, repo }, PROJECTION, (error, deployments) =>
      return callback error if error?
      callback null, _.map deployments, @_mapDeployment

  _mapDeployment: (deployment) =>
    deployment = @_convertDates deployment
    deployment.build = _.mapValues deployment.build, @_convertDates
    deployment.cluster = _.mapValues deployment.cluster, @_convertDates
    return deployment

  _convertDates: (obj) =>
    obj.createdAt = moment(obj.createdAt).valueOf() if obj.createdAt?
    obj.updatedAt = moment(obj.updatedAt).valueOf() if obj.updatedAt?
    return obj

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DeployStateService
