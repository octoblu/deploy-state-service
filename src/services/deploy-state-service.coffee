_     = require 'lodash'
async = require 'async'

class DeployStateService
  constructor: ({ database, @travisProService, @travisOrgService }) ->
    @deployments = database.collection 'deployments'

  getDeployment: ({ owner, repo, tag }, callback) =>
    projection =
      _id:   false
      tag:   true
      owner: true
      repo:  true
      state: true

    @deployments.findOne { owner, repo, tag }, projection, (error, deployment) =>
      return callback error if error?
      return callback @_createError(404, 'Unable to find deployment') unless deployment?
      @getTravisStatus { owner, repo, tag }, (error, passed) =>
        return callback error if error?
        deployment.valid = deployment.valid && passed
        callback null, deployment

  getTravisStatus: ({ owner, repo, tag }, callback) =>
    async.series [
      async.apply @travisProService.getBuild, { owner, repo, tag }
      async.apply @travisOrgService.getBuild, { owner, repo, tag }
    ], (error, result) =>
      return callback error if error?
      passed = _.isEmpty _.compact result
      callback null, passed

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DeployStateService
