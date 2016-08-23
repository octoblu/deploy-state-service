request       = require 'request'
mongojs       = require 'mongojs'
TravisMock    = require '../mocks/travis-mock.coffee'
Server        = require '../../src/server'

describe 'List Deployments', ->
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

  describe 'on GET /deployments/the-owner/the-service', ->
    describe 'when deployments exist', ->
      beforeEach (done) ->
        deployment =
          tag:  'v1.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          state: {
            disabled: false
            errors: {
              count: 0
            }
          }
        @deployments.insert deployment, done

      beforeEach (done) ->
        deployment =
          tag:  'v2.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          state: {
            disabled: false
            errors: {
              count: 0
            }
          }
        @deployments.insert deployment, done

      beforeEach (done) ->
        response = {
          branch: {
            state: 'passed'
          }
        }
        @getOrgBuildv1 = @travisOrg.getBuild { slug: 'the-owner/the-service', tag: 'v1.0.0' }, { code: 200, response }
        @getProBuildv1 = @travisPro.getBuild { slug: 'the-owner/the-service', tag: 'v1.0.0' }, { code: 404 }
        response = {
          branch: {
            state: 'failed'
          }
        }
        @getOrgBuildv2 = @travisOrg.getBuild { slug: 'the-owner/the-service', tag: 'v2.0.0' }, { code: 200, response }
        @getProBuildv2 = @travisPro.getBuild { slug: 'the-owner/the-service', tag: 'v2.0.0' }, { code: 404 }
        options =
          uri: '/deployments/the-owner/the-service'
          baseUrl: "http://localhost:#{@serverPort}"
          headers: {
            Authorization: 'token deploy-state-key'
          }
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should have the list of deployments', ->
        expect(@body.deployments).to.deep.equal [
          {
            tag:  'v1.0.0'
            repo: 'the-service'
            owner: 'the-owner'
            state: {
              disabled: false
              valid: true
              travis: {
                passing: true
              }
              errors: {
                count: 0
              }
            }
          }
          {
            tag:  'v2.0.0'
            repo: 'the-service'
            owner: 'the-owner'
            state: {
              disabled: false
              valid: false
              travis: {
                passing: false
              }
              errors: {
                count: 0
              }
            }
          }
        ]

      it 'should have get the builds from travis org', ->
        @getOrgBuildv1.done()
        @getOrgBuildv2.done()

      it 'should have get the builds from travis pro', ->
        @getProBuildv1.done()
        @getProBuildv2.done()

    describe 'when no deployments exist', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service'
          baseUrl: "http://localhost:#{@serverPort}"
          headers: {
            Authorization: 'token deploy-state-key'
          }
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should have an empty list of deployments', ->
        expect(@body.deployments).to.deep.equal []

