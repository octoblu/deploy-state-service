request  = require 'request'
moment   = require 'moment'
Database = require '../database'
Server   = require '../../src/server'

describe 'Update Build Passed', ->
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

  describe 'on PUT /deployments/:owner/:repo/:tag/build/:state/passed', ->
    describe 'when the deployment does NOT exist', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0/build/travis-ci/passed'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
          json: true

        request.put options, (error, @response, @body) =>
          done error

      it 'should return a 404', ->
        expect(@response.statusCode).to.equal 404

      it 'should have a "Not Found"', ->
        expect(@body).to.equal 'Not Found'

    describe 'when the deployment exists', ->
      describe 'when the build does NOT exist', ->
        beforeEach (done) ->
          deployment =
            tag:  'v1.0.0'
            repo: 'the-service'
            owner: 'the-owner'
            createdAt: moment('2001-01-01').toDate()
            build: {}
            cluster: {}
          @db.deployments.insert deployment, done

        beforeEach (done) ->
          options =
            uri: '/deployments/the-owner/the-service/v1.0.0/build/travis-ci/passed'
            baseUrl: "http://localhost:#{@serverPort}"
            headers:
              Authorization: 'token deploy-state-key'
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

          it 'should have a travis-ci set to passed', ->
            expect(@record.build["travis-ci"].passing).to.be.true

          it 'should have a valid created at date for travis-ci', ->
            expect(moment(@record.build["travis-ci"].createdAt).isBefore(moment())).to.be.true
            expect(moment(@record.build["travis-ci"].createdAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

      describe 'when the build exists', ->
        beforeEach (done) ->
          deployment =
            tag:  'v1.0.0'
            repo: 'the-service'
            owner: 'the-owner'
            createdAt: moment('2001-01-01').toDate()
            build: {
              "travis-ci": {
                passing: false,
                createdAt: moment('2001-01-01').toDate()
              }
            }
            cluster: {}
          @db.deployments.insert deployment, done

        beforeEach (done) ->
          options =
            uri: '/deployments/the-owner/the-service/v1.0.0/build/travis-ci/passed'
            baseUrl: "http://localhost:#{@serverPort}"
            headers:
              Authorization: 'token deploy-state-key'
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

          it 'should have a travis-ci set to passed', ->
            expect(@record.build["travis-ci"].passing).to.be.true

          it 'should have a valid createdAt date for travis-ci', ->
            expect(moment(@record.build["travis-ci"].createdAt).valueOf()).to.be.equal moment('2001-01-01').valueOf()

          it 'should have a valid updatedAt date for travis-ci', ->
            expect(moment(@record.build["travis-ci"].updatedAt).isBefore(moment())).to.be.true
            expect(moment(@record.build["travis-ci"].updatedAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

