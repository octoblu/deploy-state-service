request  = require 'request'
Database = require '../database'
Server   = require '../../src/server'

describe 'Register Webhook', ->
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

  describe 'on POST /webhooks', ->
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
            auth:
              username: 'uuid'
              password: 'token'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201

      describe 'when the database is checked', ->
        beforeEach (done) ->
          @db.webhooks.findOne { url: 'https://some.testing.dev/webhook' }, (error, @record) =>
            done error

        it 'should have a url', ->
          expect(@record.url).to.equal 'https://some.testing.dev/webhook'

        it 'should have the auth stored', ->
          expect(@record.auth).to.deep.equal { username: 'uuid', password: 'token' }

        it 'should have no events stored', ->
          expect(@record.events).to.not.exist

    describe 'when it the events are sent', ->
      beforeEach (done) ->
        options =
          uri: '/webhooks'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json:
            url: 'https://some.testing.dev/webhook'
            events: ['create']
            auth:
              username: 'uuid'
              password: 'token'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201

      describe 'when the database is checked', ->
        beforeEach (done) ->
          @db.webhooks.findOne { url: 'https://some.testing.dev/webhook' }, (error, @record) =>
            done error

        it 'should have a url', ->
          expect(@record.url).to.equal 'https://some.testing.dev/webhook'

        it 'should have the auth stored', ->
          expect(@record.auth).to.deep.equal { username: 'uuid', password: 'token' }

        it 'should have create stored', ->
          expect(@record.events).to.deep.equal ['create']

    describe 'when it already exists', ->
      beforeEach (done) ->
        record =
          url: 'https://some.testing.dev/webhook'
          events: ['create']
          auth:
            username: 'uuid'
            password: 'token'
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
            events: ['update']
            auth:
              username: 'no'
              password: 'yes?'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

      describe 'when the database is checked', ->
        beforeEach (done) ->
          @db.webhooks.findOne { url: 'https://some.testing.dev/webhook' }, (error, @record) =>
            done error

        it 'should have a url', ->
          expect(@record.url).to.equal 'https://some.testing.dev/webhook'

        it 'should have original auth', ->
          expect(@record.auth).to.deep.equal { username: 'uuid', password: 'token' }

        it 'should have original events', ->
          expect(@record.events).to.deep.equal ['create']

    describe 'when it is missing the url', ->
      beforeEach (done) ->
        options =
          uri: '/webhooks'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json: true

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 422', ->
        expect(@response.statusCode).to.equal 422

    describe 'when it is missing the auth', ->
      beforeEach (done) ->
        options =
          uri: '/webhooks'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json:
            url: 'this-is-the-url'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201

