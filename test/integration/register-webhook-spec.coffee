request = require 'request'
mongojs = require 'mongojs'
Server  = require '../../src/server'

describe 'Register Webhook', ->
  beforeEach (done) ->
    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      deployStateKey: 'deploy-state-key'

    database = mongojs 'deploy-state-service-test', ['webhooks']
    serverOptions.database = database
    @webhooks = database.webhooks
    @webhooks.drop()

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()

  describe 'on POST /webhooks', ->
    describe 'when it does NOT already exist', ->
      beforeEach (done) ->
        options =
          uri: '/webhooks'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
          json:
            url: 'https://some.testing.dev/webhook'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201

      describe 'when the database is checked', ->
        beforeEach (done) ->
          @webhooks.findOne { url: 'https://some.testing.dev/webhook' }, (error, @record) =>
            done error

        it 'should have a record', ->
          expect(@record).to.exist

    describe 'when it already exists', ->
      beforeEach (done) ->
        record =
          url: 'https://some.testing.dev/webhook'
        @webhooks.insert record, done

      beforeEach (done) ->
        options =
          uri: '/webhooks'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
          json:
            url: 'https://some.testing.dev/webhook'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

    describe 'when it is missing the url', ->
      beforeEach (done) ->
        options =
          uri: '/webhooks'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
          json: true

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 422', ->
        expect(@response.statusCode).to.equal 422

