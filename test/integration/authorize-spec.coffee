request  = require 'request'
Database = require '../database'
Server   = require '../../src/server'

describe 'Authorize', ->
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
      travisTokenPro: 'hello-pro'
      travisTokenOrg: 'hello-org'

    serverOptions.database = @db.database

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()

  describe 'on GET /authorize', ->
    describe 'when authorized', ->
      beforeEach (done) ->
        options =
          uri: '/authorize'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

    describe 'when missing the authorization key', ->
      beforeEach (done) ->
        options =
          uri: '/authorize'
          baseUrl: "http://localhost:#{@serverPort}"
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 401', ->
        expect(@response.statusCode).to.equal 401

    describe 'when the authorization key is wrong', ->
      beforeEach (done) ->
        options =
          uri: '/authorize'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'wrong'
            password: 'wrong'
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 401', ->
        expect(@response.statusCode).to.equal 401

