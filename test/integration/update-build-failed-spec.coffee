request  = require 'request'
moment   = require 'moment'
Database = require '../database'
Server   = require '../../src/server'

describe 'Update Build Failed', ->
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

  describe 'on PUT /deployments/:owner/:repo/:tag/build/:state/failed', ->
    describe 'when the deployment does NOT exist', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/the-owner/the-service/v1.0.0/build/travis-ci/failed'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json: true

        request.put options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

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
            uri: '/deployments/the-owner/the-service/v1.0.0/build/travis-ci/failed'
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

          it 'should have a failed build', ->
            expect(@record.build.passing).to.be.false

          it 'should have a travis-ci set to failed', ->
            expect(@record.build["travis-ci"].passing).to.be.false

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
              passing: true
              "travis-ci": {
                passing: true,
                createdAt: moment('2001-01-01').toDate()
              }
            }
            cluster: {}
          @db.deployments.insert deployment, done

        beforeEach (done) ->
          options =
            uri: '/deployments/the-owner/the-service/v1.0.0/build/travis-ci/failed'
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

          it 'should have a non-passing build', ->
            expect(@record.build.passing).to.be.false

          it 'should have a travis-ci set to failed', ->
            expect(@record.build["travis-ci"].passing).to.be.false

          it 'should have a valid createdAt date for travis-ci', ->
            expect(moment(@record.build["travis-ci"].createdAt).valueOf()).to.be.equal moment('2001-01-01').valueOf()

          it 'should have a valid updatedAt date for travis-ci', ->
            expect(moment(@record.build["travis-ci"].updatedAt).isBefore(moment())).to.be.true
            expect(moment(@record.build["travis-ci"].updatedAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

