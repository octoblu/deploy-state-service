request       = require 'request'
mongojs       = require 'mongojs'
TravisMock    = require '../mocks/travis-mock.coffee'
Server        = require '../../src/server'

describe 'Create Deployment', ->
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

  describe 'on POST /deployments/the-owner/the-service/v1.0.0', ->
    describe 'when does not exist', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          headers: {
            Authorization: 'token deploy-state-key'
          }
          json: true

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201

      it 'should have a "Created"', ->
        expect(@body).to.equal 'Created'

      describe 'when the database record is checked', ->
        beforeEach (done) ->
          query = { owner: 'the-owner', repo: 'the-service', tag: 'v1.0.0' }
          @deployments.findOne query, (error, @record) =>
            done error

        it 'should have disabled to false', ->
          expect(@record.state.disabled).to.be.false

        it 'should have an error count of 0', ->
          expect(@record.state.errors.count).to.equal 0

      describe 'when it is called again', ->
        beforeEach (done) ->
          options =
            uri: '/deployments/the-owner/the-service/v1.0.0'
            baseUrl: "http://localhost:#{@serverPort}"
            headers: {
              Authorization: 'token deploy-state-key'
            }
            json: true

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 204', ->
          expect(@response.statusCode).to.equal 204

        it 'should no body', ->
          expect(@body).to.be.empty

