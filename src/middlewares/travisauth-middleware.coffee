request = require 'request'
crypto  = require 'crypto'
debug   = require('debug')('deploy-state-service:travis-auth')

TRAVIS_PRO_URI = 'https://api.travis-ci.com/config'
TRAVIS_ORG_URI = 'https://api.travis-ci.org/config'

class TravisAuth
  constructor: ({ @disableTravisAuth }) ->

  authPro: (request, response, next) =>
    @_getProPublicKey @_handleResponse request, response, next

  authOrg: (request, response, next) =>
    @_getOrgPublicKey @_handleResponse request, response, next

  _handleResponse: (request, response, next) =>
    return (error, pub) =>
      return response.sendError error if error?
      return next() if @disableTravisAuth
      payload = JSON.stringify request.body?.payload
      return response.sendStatus(401) unless payload?
      signature = request.get 'HTTP_SIGNATURE'
      return response.sendStatus(401) unless signature
      verified = @_verifySignature payload, signature, pub
      debug 'verifying payload', payload, verified
      return response.sendStatus(401) unless verified
      next()

  _verifySignature: (payload, signature, pub) =>
    verify = crypto.createVerify 'SHA1'
    verify.update payload
    return verify.verify pub, signature

  _getOrgPublicKey: (callback) =>
    return callback null, @_orgPublicKey if @_orgPublicKey?
    options =
      uri: TRAVIS_ORG_URI
      json: true
    request.get options, (error, response, body) =>
      return callback error if error?
      return callback body if response.statusCode > 299
      @_orgPublicKey = body?.config?.notifications?.webhook?.public_key
      callback null, @_orgPublicKey

  _getProPublicKey: (callback) =>
    return callback null, @_proPublicKey if @_proPublicKey?
    options =
      uri: TRAVIS_PRO_URI
      json: true
    request.get options, (error, response, body) =>
      return callback error if error?
      return callback body if response.statusCode > 299
      @_proPublicKey = body?.config?.notifications?.webhook?.public_key
      callback null, @_proPublicKey

module.exports = TravisAuth
