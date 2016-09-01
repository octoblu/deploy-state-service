request  = require 'request'
moment   = require 'moment'
Database = require '../database'
Server   = require '../../src/server'

describe 'List Deployments', ->
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

  describe 'on GET /deployments/:owner/:repo', ->
    describe 'when deployments exist', ->
      beforeEach (done) ->
        deployment =
          tag:  'v1.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          createdAt: moment('2001-01-01').toDate()
          build:
            passing: true
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
        @db.deployments.insert deployment, done

      beforeEach (done) ->
        deployment =
          tag:  'v2.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          createdAt: moment('2001-01-01').toDate()
          build:
            passing: false
            "travis-ci":
              passing: true,
              createdAt: moment('2001-01-01').toDate()
            "docker":
              passing: false,
              createdAt: moment('2001-01-01').toDate()
          cluster: {}

        @db.deployments.insert deployment, done

      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
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
              passing: true,
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
              passing: false,
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
          auth:
            username: 'username'
            password: 'password'
          json: true

        request.get options, (error, @response, @body) =>
          done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should have an empty list of deployments', ->
        expect(@body.deployments).to.deep.equal []

