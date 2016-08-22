cors               = require 'cors'
morgan             = require 'morgan'
express            = require 'express'
bodyParser         = require 'body-parser'
compression        = require 'compression'
OctobluRaven       = require 'octoblu-raven'
enableDestroy      = require 'server-destroy'
sendError          = require 'express-send-error'
expressVersion     = require 'express-package-version'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
authorize          = require './middlewares/authorize'
Router             = require './router'
DeployStateService = require './services/deploy-state-service'
debug              = require('debug')('deploy-state-service:server')

class Server
  constructor: ({@logFn, @disableLogging, @port, @deployStateKey, @octobluRaven})->
    throw new Error 'Missing deployStateKey' unless @deployStateKey?
    @octobluRaven ?= new OctobluRaven()

  address: =>
    @server.address()

  skip: (request, response) =>
    return true if @disableLogging
    return response.statusCode < 400

  run: (callback) =>
    app = express()

    app.use expressVersion { format: '{"version": "%s"}' }
    app.use meshbluHealthcheck()

    ravenExpress = @octobluRaven.express()
    app.use ravenExpress.handleErrors()
    app.use sendError({ @logFn })
    app.use cors()
    app.use bodyParser.urlencoded { limit: '1mb', extended : true }
    app.use bodyParser.json { limit : '1mb' }

    app.use authorize.auth({ @deployStateKey })

    app.options '*', cors()

    deployStateService = new DeployStateService
    router = new Router {deployStateService}

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
