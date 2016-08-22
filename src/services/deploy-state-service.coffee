class DeployStateService
  constructor: ({ database }) ->
    @deployments = database.collection 'deployments'

  getDeployment: ({ service, tag }, callback) =>
    @deployments.findOne { service, tag }, (error, deployment) =>
      return callback error if error?
      return callback @_createError 404, 'Unable to find deployment' unless deployment?
      callback(null, {
        overall: {
          color: 'green'
        },
        errors: {
          count: 0
        }
      })

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DeployStateService
