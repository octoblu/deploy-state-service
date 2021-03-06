_       = require 'lodash'
async   = require 'async'
moment  = require 'moment'
request = require 'request'
debug   = require('debug')('deploy-state-service:service')

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
      return callback null, null, 404 unless deployment?
      callback null, deployment

  createDeployment: ({ owner, repo, tag, date }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback null, 204 if deployment?
      @_create { owner, repo, tag, date }, (error) =>
        return callback error if error?
        @_notifyAll 'create', { owner, repo, tag }, (error) =>
          return callback error if error?
          callback null, 201

  upsertDeployment: ({ owner, repo, tag, key, passing, date, dockerUrl }, callback) =>
    @_findOrCreate { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      @_update deployment, { owner, repo, tag, key, passing, date, dockerUrl }, (error) =>
        return callback error if error?
        @_notifyAll 'update', { owner, repo, tag }, (error) =>
          return callback error if error?
          callback null, 204

  listDeployments: ({ owner, repo }, callback) =>
    @_findDeployments { owner, repo }, callback

  registerWebhook: ({ url, auth, events }, callback) =>
    @webhooks.findOne { url }, (error, webhook) =>
      return callback error if error?
      return callback null, 204 if webhook?
      @webhooks.insert { url, auth, events }, (error) =>
        return callback error if error?
        callback null, 201

  deleteWebhook: ({ url }, callback) =>
    @webhooks.findOne { url }, (error, webhook) =>
      return callback error if error?
      return callback null, 404 unless webhook?
      @webhooks.remove { url }, (error) =>
        return callback error if error?
        callback null, 204

  _create: ({ owner, repo, tag, date }, callback) =>
    record = {
      owner,
      repo,
      tag,
      build: { passing: false },
      cluster: {},
      createdAt: @_getDate(date)
    }
    @deployments.insert record, callback

  _findOrCreate: ({ owner, repo, tag, key, passing, date }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback null, deployment if deployment
      @_create { owner, repo, tag, date }, (error) =>
        return callback error if error?
        @_findDeployment { owner, repo, tag }, callback

  _update: (deployment, { owner, repo, tag, key, passing, date, dockerUrl }, callback) =>
    query = {}
    query["build.passing"]    = @_buildPassing deployment, "#{key}.passing", passing
    query["build.dockerUrl"]  = dockerUrl if dockerUrl?
    query["#{key}.passing"]   = passing
    query["#{key}.createdAt"] = @_getDate(date) unless _.get deployment, "#{key}.createdAt"
    query["#{key}.updatedAt"] = @_getDate(date) if _.get deployment, "#{key}.createdAt"

    @deployments.update { owner, repo, tag }, { $set: query }, callback

  _buildPassing: (deployment, key, value) =>
    deployment = _.cloneDeep deployment
    _.set deployment, key, value
    return false unless _.get deployment, "build.travis-ci.passing"
    return false unless _.get deployment, "build.docker.passing"
    return true

  _notifyAll: (command, { owner, repo, tag }, callback) =>
    debug 'notifying all', { command }
    @webhooks.find {}, (error, webhooks) =>
      debug 'got webhooks', { error, webhooks }
      return callback error if error?
      return callback null if _.isEmpty webhooks
      @_findDeployment { owner, repo, tag }, (error, deployment) =>
        return callback error if error?
        async.each webhooks, async.apply(@_notify, command, deployment), callback

  _notify: (command, deployment, { url, auth, events }, callback) =>
    events = ['create', 'update'] if _.isEmpty events
    return callback null unless command in events
    method = 'PUT'
    method = 'POST' if command == 'create'
    options = {
      url,
      method,
      auth,
      json: deployment
    }
    debug 'notifying', options
    request options, (error, response, body) =>
      return callback error if error?
      debug 'notify response', { url, statusCode: response.statusCode, body }
      callback null

  _getDate: (date) =>
    newDate = moment(parseInt(date)) if date? && /^[0-9]+$/.test date
    newDate ?= moment(date) if date?
    newDate ?= moment()
    return newDate.toDate()

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
