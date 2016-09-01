crypto = require 'crypto'

class TravisAuth
  constructor: ({ @travisToken }) ->
    throw new Error 'Missing travisToken' unless @travisToken?

  encrypt: (data) =>
    return crypto.createHash('sha256')
      .update "#{@travisToken}#{data}"
      .digest 'hex'

  auth: =>
    return @_middleware

  _middleware: (request, response, next) =>
    authString = @encrypt request.get('Travis-Repo-Slug')
    return response.sendStatus(401) unless authString == request.get('Authorization')
    return response.sendStatus(400) unless @_validate request.body.payload
    next()

  _validate: (payload) =>
    return false unless payload?
    return false unless payload.status?
    return false unless payload.branch?
    return false unless payload.repository?
    return true


module.exports = TravisAuth
