_     = require 'lodash'
async = require 'async'

PROJECTION =
  _id:   false
  tag:   true
  owner: true
  repo:  true
  state: true

class DeployStateService
  constructor: ({ database, @travisProService, @travisOrgService }) ->
    @deployments = database.collection 'deployments'

  getDeployment: ({ owner, repo, tag }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback @_createError(404, 'Unable to find deployment') unless deployment?
      @_mapDeployment deployment, callback

  createDeployment: ({ owner, repo, tag }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback null, 204 if deployment?
      state = { disabled: false, errors: { count: 0 } }
      record = { owner, repo, tag, state }
      @deployments.insert record, (error) =>
        return callback error if error?
        callback null, 201

  listDeployments: ({ owner, repo }, callback) =>
    @_findDeployments { owner, repo }, (error, deployments) =>
      return callback error if error?
      async.map deployments, @_mapDeployment, (error, deployments) =>
        return callback error if error?
        callback null, deployments

  getTravisStatus: ({ owner, repo, tag }, callback) =>
    async.parallel [
      async.apply @travisProService.getBuild, { owner, repo, tag }
      async.apply @travisOrgService.getBuild, { owner, repo, tag }
    ], (error, result) =>
      return callback error if error?
      passing = !_.isEmpty _.compact result
      callback null, passing

  _mapDeployment: (deployment, callback) =>
    { owner, repo, tag } = deployment
    @getTravisStatus { owner, repo, tag }, (error, passing) =>
      return callback error if error?
      deployment.state.travis = { passing }
      deployment.state.valid = !deployment.state.disabled && passing
      callback null, deployment

  _findDeployment: ({ owner, repo, tag }, callback) =>
    @deployments.findOne { owner, repo, tag }, PROJECTION, callback

  _findDeployments: ({ owner, repo }, callback) =>
    @deployments.find { owner, repo }, PROJECTION, callback

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DeployStateService
