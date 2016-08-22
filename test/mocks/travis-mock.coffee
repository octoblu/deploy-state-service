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

  getBuilds: ({ owner, repo }, { code, response }) =>
    return @server
      .get "/repos/#{owner}/#{repo}/builds"
      .set 'Authorization', "token #{@token}"
      .reply code, response

module.exports = TravisMock
