request  = require 'request'
Database = require '../database'
Server   = require '../../src/server'

describe 'Delete Webhook', ->
  beforeEach (done) ->
    @db = new Database
    @db.drop done

  beforeEach (done) ->
    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      username: 'username'
      password: 'password'

    serverOptions.database = @db.database

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()

  describe 'on DELETE /webhooks', ->
    describe 'when it does NOT already exist', ->
      beforeEach (done) ->
        options =
          uri: '/webhooks'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json:
            url: 'https://some.testing.dev/webhook'

        request.del options, (error, @response, @body) =>
          done error

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404

    describe 'when it already exists', ->
      beforeEach (done) ->
        record =
          url: 'https://some.testing.dev/webhook'
        @db.webhooks.insert record, done

      beforeEach (done) ->
        options =
          uri: '/webhooks'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json:
            url: 'https://some.testing.dev/webhook'

        request.del options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

      describe 'when the database is checked', ->
        beforeEach (done) ->
          @db.webhooks.findOne { url: 'https://some.testing.dev/webhook' }, (error, @record) =>
            done error

        it 'should NOT have a record', ->
          expect(@record).to.not.exist

    describe 'when it is missing the url', ->
      beforeEach (done) ->
        options =
          uri: '/webhooks'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json: true

        request.del options, (error, @response, @body) =>
          done error

      it 'should return a 422', ->
        expect(@response.statusCode).to.equal 422

