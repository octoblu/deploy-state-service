request       = require 'request'
mongojs       = require 'mongojs'
TravisMock    = require '../mocks/travis-mock.coffee'
Server        = require '../../src/server'

describe 'Get Deployment', ->
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

  describe 'on GET /deployments/the-owner/the-service/v1.0.0', ->
    describe 'when it exists', ->
      beforeEach (done) ->
        deployment =
          tag:  'v1.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          state: {
            valid: true
            color: 'green'
            errors: {
              count: 0
            }
          }
        @deployments.insert deployment, done

      beforeEach (done) ->
        response = [
          { branch: 'v1.0.0' }
        ]
        @getOrgBuilds = @travisOrg.getBuilds { repo: 'the-service', owner: 'the-owner' }, { code: 200, response }
        @getProBuilds = @travisPro.getBuilds { repo: 'the-service', owner: 'the-owner' }, { code: 404 }
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          headers: {
            Authorization: 'token deploy-state-key'
          }
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should not return the mongo id', ->
        expect(@body._id).to.not.exist

      it 'should have the service owner in the response', ->
        expect(@body.owner).to.equal 'the-owner'

      it 'should have the service repo in the response', ->
        expect(@body.repo).to.equal 'the-service'

      it 'should have the tag in the response', ->
        expect(@body.tag).to.equal 'v1.0.0'

      it 'should be valid', ->
        expect(@body.state.valid).to.be.true

      it 'should have the overall state set to green', ->
        expect(@body.state.color).to.equal 'green'

      it 'should have an error count of 0', ->
        expect(@body.state.errors).to.deep.equal {
          count: 0
        }

      it 'should have get the builds from travis org', ->
        @getOrgBuilds.done()

      it 'should have get the builds from travis pro', ->
        @getOrgBuilds.done()

    describe 'when it missing', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          headers: {
            Authorization: 'token deploy-state-key'
          }
          json: true

        request.get options, (error, @response) =>
          done error

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404

