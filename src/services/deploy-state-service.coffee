class DeployStateService
  getDeployment: ({ service, tag }, callback) =>
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
