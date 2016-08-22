class DeployStateService
  doHello: ({hasError}, callback) =>
    return callback @_createError(755, 'Not enough dancing!') if hasError?
    callback()

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DeployStateService
