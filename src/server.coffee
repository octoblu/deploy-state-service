octobluExpress = require 'express-octoblu'
enableDestroy  = require 'server-destroy'
debug          = require('debug')('deploy-state-service:server')

Router             = require './router'
DeployStateService = require './services/deploy-state-service'

class Server
  constructor: (options) ->
    { @logFn, @disableLogging, @port } = options
    { @database, @username, @password } = options
    { @travisTokenPro, @travisTokenOrg } = options
    throw new Error 'Missing database' unless @database?
    throw new Error 'Missing username' unless @username?
    throw new Error 'Missing password' unless @password?
    throw new Error 'Missing travisTokenPro' unless @travisTokenPro?
    throw new Error 'Missing travisTokenOrg' unless @travisTokenOrg?

  address: =>
    @server.address()

  skip: (request, response) =>
    return true if @disableLogging
    return response.statusCode < 400

  run: (callback) =>
    app = octobluExpress({ @logFn, @octobluRaven, @disableLogging })

    deployStateService = new DeployStateService { @database }
    router = new Router { deployStateService, @username, @password, @travisTokenOrg, @travisTokenPro }

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
