shmock        = require 'shmock'
enableDestroy = require 'server-destroy'

class TravisMock
  constructor: ({ @token }) ->
    @server = shmock()
    enableDestroy @server

  getUrl: =>
    { port } = @server.address()
    return "http://localhost:#{port}"

  getToken: =>
    return @token

  destroy: =>
    @server.destroy()

  getBuild: ({ slug, tag }, { code, response }) =>
    return @server
      .get "/repos/#{slug}/branches/#{tag}"
      .set 'Authorization', "token #{@token}"
      .reply code, response

  getBuilds: ({ slug }, { code, response }) =>
    return @server
      .get "/repos/#{slug}/builds"
      .set 'Authorization', "token #{@token}"
      .reply code, response

module.exports = TravisMock
