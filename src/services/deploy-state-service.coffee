_     = require 'lodash'
async = require 'async'

class DeployStateService
  constructor: ({ database, @travisProService, @travisOrgService }) ->
    @deployments = database.collection 'deployments'

  getDeployment: ({ owner, repo, tag }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback @_createError(404, 'Unable to find deployment') unless deployment?
      @getTravisStatus { owner, repo, tag }, (error, passing) =>
        return callback error if error?
        deployment.valid = !deployment.state.disabled && passing
        callback null, deployment

  createDeployment: ({ owner, repo, tag }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback null, 204 if deployment?
      state = { disabled: false, errors: { count: 0 } }
      record = { owner, repo, tag, state }
      @deployments.insert record, (error) =>
        return callback error if error?
        callback null, 201

  _findDeployment: ({ owner, repo, tag }, callback) =>
    projection =
      _id:   false
      tag:   true
      owner: true
      repo:  true
      state: true

    @deployments.findOne { owner, repo, tag }, projection, callback

  getTravisStatus: ({ owner, repo, tag }, callback) =>
    async.parallel [
      async.apply @travisProService.getBuild, { owner, repo, tag }
      async.apply @travisOrgService.getBuild, { owner, repo, tag }
    ], (error, result) =>
      return callback error if error?
      passing = !_.isEmpty _.compact result
      callback null, passing

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DeployStateService
