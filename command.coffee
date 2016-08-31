_             = require 'lodash'
mongojs       = require 'mongojs'
Server        = require './src/server'

class Command
  constructor: ->
    @mongoDbUri    = process.env.MONGODB_URI
    @serverOptions = {
      port:           process.env.PORT || 80
      disableLogging: process.env.DISABLE_LOGGING == "true"
      username: process.env.DEPLOY_STATE_USERNAME
      password: process.env.DEPLOY_STATE_PASSWORD
    }

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    @panic new Error('Missing required environment variable: MONGODB_URI') unless @mongoDbUri?
    @panic new Error('Missing required environment variable: DEPLOY_STATE_USERNAME') unless @serverOptions.username?
    @panic new Error('Missing required environment variable: DEPLOY_STATE_PASSWORD') unless @serverOptions.password?
    @panic new Error('Missing port') unless @serverOptions.port?

    database = mongojs @mongoDbUri, ['deployments', 'webhooks']
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
command.run()
