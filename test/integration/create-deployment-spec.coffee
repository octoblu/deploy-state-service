request  = require 'request'
mongojs  = require 'mongojs'
moment   = require 'moment'
Database = require '../database'
Server   = require '../../src/server'

describe 'Create Deployment', ->
  beforeEach (done) ->
    @db = new Database
    @db.drop done

  beforeEach (done) ->
    @logFn = sinon.spy()

    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      deployStateKey: 'deploy-state-key'

    serverOptions.database = @db.database

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()

  describe 'on POST /deployments/:owner/:repo/:tag', ->
    describe 'when does not exist', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
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
          @db.deployments.findOne query, (error, @record) =>
            done error

        it 'should have a valid created at date', ->
          expect(moment(@record.createdAt).isBefore(moment())).to.be.true
          expect(moment(@record.createdAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

        it 'should have an empty build', ->
          expect(@record.build).to.deep.equal {}

        it 'should have an empty cluster', ->
          expect(@record.cluster).to.deep.equal {}

      describe 'when it is called again', ->
        beforeEach (done) ->
          options =
            uri: '/deployments/the-owner/the-service/v1.0.0'
            baseUrl: "http://localhost:#{@serverPort}"
            headers:
              Authorization: 'token deploy-state-key'
            json: true

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 204', ->
          expect(@response.statusCode).to.equal 204

        it 'should no body', ->
          expect(@body).to.be.empty

