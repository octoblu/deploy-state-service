_             = require 'lodash'
mongojs       = require 'mongojs'
OctobluRaven  = require 'octoblu-raven'
Server        = require './src/server'

class Command
  constructor: ->
    @octobluRaven  = new OctobluRaven()
    @mongoDbUri    = process.env.MONGODB_URI
    @serverOptions = {
      port:           process.env.PORT || 80
      disableLogging: process.env.DISABLE_LOGGING == "true"
      deployStateKey: process.env.DEPLOY_STATE_KEY
      travisOrgUrl:   process.env.TRAVIS_ORG_URL
      travisOrgToken: process.env.TRAVIS_ORG_TOKEN
      travisProUrl:   process.env.TRAVIS_PRO_URL
      travisProToken: process.env.TRAVIS_PRO_TOKEN
      @octobluRaven,
    }

  handleErrors: =>
    @octobluRaven.patchGlobal()

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    @panic new Error('Missing required environment variable: MONGODB_URI') unless @mongoDbUri?
    @panic new Error('Missing required environment variable: TRAVIS_ORG_URL') unless @serverOptions.travisOrgUrl?
    @panic new Error('Missing required environment variable: TRAVIS_ORG_TOKEN') unless @serverOptions.travisOrgToken?
    @panic new Error('Missing required environment variable: TRAVIS_PRO_URL') unless @serverOptions.travisProUrl?
    @panic new Error('Missing required environment variable: TRAVIS_PRO_TOKEN') unless @serverOptions.travisProToken?
    @panic new Error('Missing required environment variable: DEPLOY_STATE_KEY') unless @serverOptions.deployStateKey?
    @panic new Error('Missing port') unless @serverOptions.port?

    database = mongojs @mongoDbUri, ['deployments']
    database.on 'error', @panic
    database.on 'connect', =>
      @serverOptions.database = database

      server = new Server @serverOptions
      server.run (error) =>
        return @panic error if error?

        {address,port} = server.address()
        console.log "DeployStateService listening on port: #{port}"

    process.on 'SIGTERM', =>
      console.log 'SIGTERM caught, exiting'
      database?.close()
      process.exit 0 unless server?.stop?
      server.stop =>
        process.exit 0

command = new Command()
command.handleErrors()
command.run()
