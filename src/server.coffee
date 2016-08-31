octobluExpress = require 'express-octoblu'
enableDestroy  = require 'server-destroy'
basicauth      = require 'basicauth-middleware'
debug          = require('debug')('deploy-state-service:server')

Router             = require './router'
DeployStateService = require './services/deploy-state-service'

class Server
  constructor: (options) ->
    { @logFn, @disableLogging, @port } = options
    { @database, @username, @password } = options
    throw new Error 'Missing database' unless @database?
    throw new Error 'Missing username' unless @username?
    throw new Error 'Missing password' unless @password?

  address: =>
    @server.address()

  skip: (request, response) =>
    return true if @disableLogging
    return response.statusCode < 400

  run: (callback) =>
    app = octobluExpress({ @logFn, @octobluRaven, @disableLogging })

    app.use basicauth @username, @password

    deployStateService = new DeployStateService { @database }
    router = new Router { deployStateService }

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
