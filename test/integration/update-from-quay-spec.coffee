request  = require 'request'
moment   = require 'moment'
Database = require '../database'
Server   = require '../../src/server'

describe 'Update From Quay', ->
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

  describe 'on POST /deployments/quay.io', ->
    describe 'when the deployment does NOT exist', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/quay.io'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json:
            name: 'the-service'
            namespace: 'the-owner'
            docker_url: 'quay.io/the-owner/the-service'
            updated_tags: [
              'v1.0.0'
            ]

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201

    describe 'when the deployment exists', ->
      describe 'when the build does NOT exist', ->
        beforeEach (done) ->
          deployment =
            tag:  'v1.0.0'
            repo: 'the-service'
            owner: 'the-owner'
            createdAt: moment('2001-01-01').toDate()
            build: {
              passing: false
              "travis-ci": {
                passing: true
              }
            }
            cluster: {}
          @db.deployments.insert deployment, done

        beforeEach (done) ->
          options =
            uri: '/deployments/quay.io'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'username'
              password: 'password'
            json:
              name: 'the-service'
              namespace: 'the-owner'
              docker_url: 'quay.io/the-owner/the-service'
              updated_tags: [
                'v1.0.0'
              ]

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 201', ->
          expect(@response.statusCode).to.equal 201

        describe 'when the database record is checked', ->
          beforeEach (done) ->
            query = { owner: 'the-owner', repo: 'the-service', tag: 'v1.0.0' }
            @db.deployments.findOne query, (error, @record) =>
              done error

          it 'should have the dockerUrl', ->
            expect(@record.build.dockerUrl).to.equal 'quay.io/the-owner/the-service:v1.0.0'

          it 'should be passing', ->
            expect(@record.build.passing).to.be.true

          it 'should have a docker set to passed', ->
            expect(@record.build["docker"].passing).to.be.true

          it 'should have a valid created at date for docker', ->
            expect(moment(@record.build["docker"].createdAt).isBefore(moment())).to.be.true
            expect(moment(@record.build["docker"].createdAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

      describe 'when the build exists', ->
        beforeEach (done) ->
          deployment =
            tag:  'v1.0.0'
            repo: 'the-service'
            owner: 'the-owner'
            createdAt: moment('2001-01-01').toDate()
            build: {
              passing: false,
              "docker": {
                passing: false
              }
              "travis-ci": {
                passing: true
              }
            }
            cluster: {}
          @db.deployments.insert deployment, done

        beforeEach (done) ->
          options =
            uri: '/deployments/quay.io'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'username'
              password: 'password'
            json:
              name: 'the-service'
              namespace: 'the-owner'
              docker_url: 'quay.io/the-owner/the-service'
              updated_tags: [
                'v1.0.0'
              ]

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 201', ->
          expect(@response.statusCode).to.equal 201

        describe 'when the database record is checked', ->
          beforeEach (done) ->
            query = { owner: 'the-owner', repo: 'the-service', tag: 'v1.0.0' }
            @db.deployments.findOne query, (error, @record) =>
              done error

          it 'should have the dockerUrl', ->
            expect(@record.build.dockerUrl).to.equal 'quay.io/the-owner/the-service:v1.0.0'

          it 'should be passing', ->
            expect(@record.build.passing).to.be.true

          it 'should have a docker set to passed', ->
            expect(@record.build["docker"].passing).to.be.true

          it 'should have a valid created at date for docker', ->
            expect(moment(@record.build["docker"].createdAt).isBefore(moment())).to.be.true
            expect(moment(@record.build["docker"].createdAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

