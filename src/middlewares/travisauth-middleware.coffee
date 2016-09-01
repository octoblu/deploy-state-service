crypto = require 'crypto'

class TravisAuth
  constructor: ({ @travisTokenPro, @travisTokenOrg }) ->
    throw new Error 'Missing travisTokenOrg' unless @travisTokenOrg?
    throw new Error 'Missing travisTokenPro' unless @travisTokenPro?

  encryptOrg: (data) =>
    return crypto.createHash('sha256')
      .update "#{@travisTokenOrg}#{data}"
      .digest 'hex'

  encryptPro: (data) =>
    return crypto.createHash('sha256')
      .update "#{@travisTokenPro}#{data}"
      .digest 'hex'

  auth: =>
    return @_middleware

  _middleware: (request, response, next) =>
    orgAuth = @encryptOrg request.get('Travis-Repo-Slug')
    proAuth = @encryptPro request.get('Travis-Repo-Slug')
    return response.sendStatus(401) unless request.get('Authorization') in [orgAuth, proAuth]
    return response.sendStatus(400) unless @_validate request.body.payload
    next()

  _validate: (payload) =>
    return false unless payload?
    return false unless payload.status?
    return false unless payload.branch?
    return false unless payload.repository?
    return true


module.exports = TravisAuth
