request       = require 'request'
mongojs       = require 'mongojs'
moment        = require 'moment'
Server        = require '../../src/server'

describe 'List Deployments', ->
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

  describe 'on GET /deployments/the-owner/the-service', ->
    describe 'when deployments exist', ->
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
        deployment =
          tag:  'v2.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          createdAt: moment('2001-01-01').toDate()
          build:
            "travis-ci":
              passing: true,
              createdAt: moment('2001-01-01').toDate()
            "docker":
              passing: false,
              createdAt: moment('2001-01-01').toDate()
          cluster: {}
        @deployments.insert deployment, done

      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
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
            createdAt: moment('2001-01-01').valueOf()
            build:
              "travis-ci":
                passing: true,
                createdAt: moment('2001-01-01').valueOf()
              "docker":
                passing: true,
                createdAt: moment('2001-01-01').valueOf()
            cluster:
              "major":
                passing: true,
                createdAt: moment('2001-01-01').valueOf()
              "minor":
                passing: true,
                createdAt: moment('2001-01-01').valueOf()
          }
          {
            tag:  'v2.0.0'
            repo: 'the-service'
            owner: 'the-owner'
            createdAt: moment('2001-01-01').valueOf()
            build:
              "travis-ci":
                passing: true,
                createdAt: moment('2001-01-01').valueOf()
              "docker":
                passing: false,
                createdAt: moment('2001-01-01').valueOf()
            cluster: {}
          }
        ]

    describe 'when no deployments exist', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should have an empty list of deployments', ->
        expect(@body.deployments).to.deep.equal []

