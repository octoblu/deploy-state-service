request = require 'request'
moment  = require 'moment'
Database = require '../database'
Server  = require '../../src/server'

describe 'Update Cluster Passed', ->
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

    serverOptions.database = @db.database

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()

  describe 'on PUT /deployments/:owner/:repo/:tag/cluster/:state/passed', ->
    describe 'when the deployment does NOT exist', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0/cluster/major/passed'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json: true

        request.put options, (error, @response, @body) =>
          done error

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404

      it 'should have a "Not Found"', ->
        expect(@body).to.equal 'Not Found'

    describe 'when the deployment exists', ->
      describe 'when the cluster does NOT exist', ->
        beforeEach (done) ->
          deployment =
            tag:  'v1.0.0'
            repo: 'the-service'
            owner: 'the-owner'
            createdAt: moment('2001-01-01').toDate()
            cluster: {}
          @db.deployments.insert deployment, done

        beforeEach (done) ->
          options =
            uri: '/deployments/the-owner/the-service/v1.0.0/cluster/major/passed'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'username'
              password: 'password'
            json: true

          request.put options, (error, @response, @body) =>
            done error

        it 'should return a 204', ->
          expect(@response.statusCode).to.equal 204

        it 'should have an empty body', ->
          expect(@body).to.be.empty

        describe 'when the database record is checked', ->
          beforeEach (done) ->
            query = { owner: 'the-owner', repo: 'the-service', tag: 'v1.0.0' }
            @db.deployments.findOne query, (error, @record) =>
              done error

          it 'should have a major set to passed', ->
            expect(@record.cluster["major"].passing).to.be.true

          it 'should have a valid created at date for major', ->
            expect(moment(@record.cluster["major"].createdAt).isBefore(moment())).to.be.true
            expect(moment(@record.cluster["major"].createdAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

      describe 'when the cluster exists', ->
        beforeEach (done) ->
          deployment =
            tag:  'v1.0.0'
            repo: 'the-service'
            owner: 'the-owner'
            createdAt: moment('2001-01-01').toDate()
            cluster: {
              "major": {
                passing: false,
                createdAt: moment('2001-01-01').toDate()
              }
            }
          @db.deployments.insert deployment, done

        beforeEach (done) ->
          options =
            uri: '/deployments/the-owner/the-service/v1.0.0/cluster/major/passed'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'username'
              password: 'password'
            json: true

          request.put options, (error, @response, @body) =>
            done error

        it 'should return a 204', ->
          expect(@response.statusCode).to.equal 204

        it 'should have an empty body', ->
          expect(@body).to.be.empty

        describe 'when the database record is checked', ->
          beforeEach (done) ->
            query = { owner: 'the-owner', repo: 'the-service', tag: 'v1.0.0' }
            @db.deployments.findOne query, (error, @record) =>
              done error

          it 'should have a major set to passed', ->
            expect(@record.cluster["major"].passing).to.be.true

          it 'should have a valid createdAt date for major', ->
            expect(moment(@record.cluster["major"].createdAt).valueOf()).to.be.equal moment('2001-01-01').valueOf()

          it 'should have a valid updatedAt date for major', ->
            expect(moment(@record.cluster["major"].updatedAt).isBefore(moment())).to.be.true
            expect(moment(@record.cluster["major"].updatedAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

