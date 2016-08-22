class Authorize
  auth: ({ @deployStateKey }) =>
    throw new Error 'Missing deployStateKey' unless @deployStateKey?
    return @_auth

  _auth: (request, response, next) =>
    authHeader = request.get 'Authorization'
    return response.sendStatus(401) unless authHeader?
    [key, value] = authHeader.split ' '
    return response.sendStatus(401) unless key == 'token'
    return response.sendStatus(401) unless value?
    deployStateKey = value.trim()
    return response.sendStatus(401) unless deployStateKey == @deployStateKey
    next()

module.exports = new Authorize
