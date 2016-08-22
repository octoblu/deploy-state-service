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
debug              = require('debug')('deploy-state-service:server')

Router             = require './router'
authorize          = require './middlewares/authorize'
TravisService      = require './services/travis-service'
DeployStateService = require './services/deploy-state-service'

class Server
  constructor: (options) ->
    { @logFn, @disableLogging, @port } = options
    { @database, @deployStateKey, @octobluRaven } = options
    { @travisOrgUrl, @travisOrgToken } = options
    { @travisProUrl, @travisProToken } = options
    throw new Error 'Missing database' unless @database?
    throw new Error 'Missing deployStateKey' unless @deployStateKey?
    throw new Error 'Missing travisOrgUrl' unless @travisOrgUrl?
    throw new Error 'Missing travisOrgToken' unless @travisOrgToken?
    throw new Error 'Missing travisProUrl' unless @travisProUrl?
    throw new Error 'Missing travisProToken' unless @travisProToken?
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

    travisOrgService = new TravisService { url: @travisOrgUrl, token: @travisOrgToken }
    travisProService = new TravisService { url: @travisProUrl, token: @travisProToken }
    deployStateService = new DeployStateService { @database, travisOrgService, travisProService }
    router = new Router { deployStateService }

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  destroy: =>
    @server.destroy()

module.exports = Server
