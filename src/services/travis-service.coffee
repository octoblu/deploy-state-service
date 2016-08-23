_            = require 'lodash'
travisStatus = require 'travis-status'

class TravisService
  constructor: ({ @url, @token }) ->
    throw new Error 'Missing url' unless @url?
    throw new Error 'Missing token' unless @token?

  getBuild: ({ owner, repo, tag }, callback) =>
    options =
      apiEndpoint: @url
      branch: tag
      repo: "#{owner}/#{repo}"
      token: @token

    travisStatus options, (error, result) =>
      return callback null, false if error?.statusCode in [403, 404]
      return callback error, false if error?
      return callback null, false unless result?.branch?
      callback null, result?.branch?.state == 'passed'

module.exports = TravisService
