request = require 'request'
mongojs = require 'mongojs'
moment  = require 'moment'
Server  = require '../../src/server'

describe 'Get Deployment', ->
  beforeEach (done) ->
    @logFn = sinon.spy()

    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      deployStateKey: 'deploy-state-key'

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

  describe 'on GET /deployments/the-owner/the-service/v1.0.0', ->
    describe 'when it exists', ->
      beforeEach (done) ->
        deployment =
          tag:  'v1.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          createdAt: moment('2001-01-01').toDate()
          build:
            "travis-ci":
              passing: true,
              createdAt: moment('2001-01-01').toDate()
            "docker":
              passing: true,
              createdAt: moment('2001-01-01').toDate()
          cluster:
            "major":
              passing: true,
              createdAt: moment('2001-01-01').toDate()
            "minor":
              passing: true,
              createdAt: moment('2001-01-01').toDate()
        @deployments.insert deployment, done

      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
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

      it 'should have valid createdAt', ->
        expect(@body.createdAt).to.be.equal moment('2001-01-01').valueOf()

      it 'should have travis passing', ->
        expect(@body.build["travis-ci"].passing).to.be.true

      it 'should have valid createdAt for travis-ci', ->
        expect(@body.build["travis-ci"].createdAt).to.be.equal moment('2001-01-01').valueOf()

      it 'should have docker passing', ->
        expect(@body.build["docker"].passing).to.be.true

      it 'should have valid createdAt for docker', ->
        expect(@body.build["docker"].createdAt).to.be.equal moment('2001-01-01').valueOf()

      it 'should have major passing', ->
        expect(@body.cluster["major"].passing).to.be.true

      it 'should have valid createdAt for major', ->
        expect(@body.cluster["major"].createdAt).to.be.equal moment('2001-01-01').valueOf()

      it 'should have minor passing', ->
        expect(@body.cluster["minor"].passing).to.be.true

      it 'should have valid createdAt for minor', ->
        expect(@body.cluster["minor"].createdAt).to.be.equal moment('2001-01-01').valueOf()

    describe 'when it missing', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
          json: true

        request.get options, (error, @response) =>
          done error

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404

