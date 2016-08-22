request       = require 'request'
mongojs       = require 'mongojs'
Server        = require '../../src/server'

describe 'Authorize', ->
  beforeEach (done) ->
    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      deployStateKey: 'deploy-state-key'
      travisOrgUrl: "http://localhost:#{0xbabe}"
      travisOrgToken: 'travis-org-token'
      travisProUrl: "http://localhost:#{0xcafe}"
      travisProToken: 'travis-pro-token'

    database = mongojs 'deploy-state-service-test', ['deployments']
    serverOptions.database = database
    @deployments = database.deployments
    @deployments.drop()

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
          headers: {
            Authorization: 'token deploy-state-key'
          }
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

    describe 'when the authorization type is wrong', ->
      beforeEach (done) ->
        options =
          uri: '/authorize'
          baseUrl: "http://localhost:#{@serverPort}"
          headers: {
            Authorization: 'wrong deploy-state-key'
          }
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
          headers: {
            Authorization: 'token not-the-deploy-state-key'
          }
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 403', ->
        expect(@response.statusCode).to.equal 403

