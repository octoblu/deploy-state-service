request       = require 'request'
mongojs       = require 'mongojs'
TravisMock    = require '../mocks/travis-mock.coffee'
Server        = require '../../src/server'

describe 'Get Travis Status', ->
  beforeEach (done) ->
    @logFn = sinon.spy()

    @travisOrg = new TravisMock { token: 'travis-org-token' }
    @travisPro = new TravisMock { token: 'travis-pro-token' }

    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      deployStateKey: 'deploy-state-key'
      travisOrgUrl: @travisOrg.getUrl()
      travisOrgToken: @travisOrg.getToken()
      travisProUrl: @travisPro.getUrl()
      travisProToken: @travisPro.getToken()

    database = mongojs 'deploy-state-service-test', ['deployments']
    serverOptions.database = database
    @deployments = database.deployments
    @deployments.drop()

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @travisOrg.destroy()
    @travisPro.destroy()
    @server.destroy()

  describe 'on GET /status/travis/the-owner/the-service/v1.0.0', ->
    describe 'when it exists', ->
      beforeEach (done) ->
        response = {
          branch: {
            state: 'passed'
          }
        }
        @getOrgBuild = @travisOrg.getBuild { slug: 'the-owner/the-service', tag: 'v1.0.0' }, { code: 200, response }
        @getProBuild = @travisPro.getBuild { slug: 'the-owner/the-service', tag: 'v1.0.0' }, { code: 403 }
        options =
          uri: '/status/travis/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          headers: {
            Authorization: 'token deploy-state-key'
          }
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should have the passing attribute set to true', ->
        expect(@body.passing).to.be.true

      it 'should have get the builds from travis org', ->
        @getOrgBuild.done()

      it 'should have get the builds from travis pro', ->
        @getProBuild.done()

    describe 'when it does NOT exists', ->
      beforeEach (done) ->
        @getOrgBuild = @travisOrg.getBuild { slug: 'the-owner/the-service', tag: 'v1.0.0' }, { code: 404 }
        @getProBuild = @travisPro.getBuild { slug: 'the-owner/the-service', tag: 'v1.0.0' }, { code: 404 }
        options =
          uri: '/status/travis/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          headers: {
            Authorization: 'token deploy-state-key'
          }
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should have the passing attribute set to false', ->
        expect(@body.passing).to.be.false

      it 'should have get the builds from travis org', ->
        @getOrgBuild.done()

      it 'should have get the builds from travis pro', ->
        @getProBuild.done()

    describe 'when the build is NOT passing', ->
      beforeEach (done) ->
        response = {
          branch: {
            state: 'failed'
          }
        }
        @getOrgBuild = @travisOrg.getBuild { slug: 'the-owner/the-service', tag: 'v1.0.0' }, { code: 200, response }
        @getProBuild = @travisPro.getBuild { slug: 'the-owner/the-service', tag: 'v1.0.0' }, { code: 404 }
        options =
          uri: '/status/travis/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          headers: {
            Authorization: 'token deploy-state-key'
          }
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should have the passing attribute set to false', ->
        expect(@body.passing).to.be.false

      it 'should have get the builds from travis org', ->
        @getOrgBuild.done()

      it 'should have get the builds from travis pro', ->
        @getProBuild.done()

