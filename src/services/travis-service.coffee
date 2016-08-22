_           = require 'lodash'
request     = require 'request'
{ version } = require '../../package.json'

class TravisService
  constructor: ({ @url, @token }) ->
    throw new Error 'Missing url' unless @url?
    throw new Error 'Missing token' unless @token?

  getBuild: ({ owner, repo, tag }, callback) =>
    options =
      uri: "/repos/#{owner}/#{repo}/builds"
      baseUrl: @url
      json: true
      headers:
        'User-Agent': "Deploy State Service/#{version}"
        'Authorization': "token #{@token}"

    request.get options, (error, response, body) =>
      return callback error if error?
      build = _.find body, { branch: tag }
      return callback null, false unless build?
      callback null, (_.isNull(build.result) || build.result == 0)

module.exports = TravisService
