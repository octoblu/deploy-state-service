class DeployStateService
  constructor: ({ database }) ->
    @deployments = database.collection 'deployments'

  getDeployment: ({ service, tag }, callback) =>
    projection =
      _id:     false
      tag:     true
      service: true
      state:   true

    @deployments.findOne { service, tag }, projection, (error, deployment) =>
      return callback error if error?
      return callback @_createError 404, 'Unable to find deployment' unless deployment?
      callback null, deployment

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DeployStateService
