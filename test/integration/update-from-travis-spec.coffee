request    = require 'request'
moment     = require 'moment'
Database   = require '../database'
Server     = require '../../src/server'
TravisAuth = require '../../src/middlewares/travisauth-middleware'

describe 'Update From Travis', ->
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

    @travisAuth = new TravisAuth { travisTokenPro: 'hello-pro', travisTokenOrg: 'hello-org' }

    serverOptions.database = @db.database

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()

  describe 'on POST /deployments/travis-ci', ->
    describe 'when the auth is missing', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/travis-ci'
          baseUrl: "http://localhost:#{@serverPort}"
          form:
            payload:
              status: 1
              branch: 'v1.0.0'
              repository:
                name: 'the-service'
                owner_name: 'the-owner'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 401', ->
        expect(@response.statusCode).to.equal 401

    describe 'when the auth is invalid', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/travis-ci'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            'Travis-Repo-Slug': 'hi2'
            'Authorization': @travisAuth.encryptOrg('hi')
          form:
            payload:
              status: 1
              branch: 'v1.0.0'
              repository:
                name: 'the-service'
                owner_name: 'the-owner'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 401', ->
        expect(@response.statusCode).to.equal 401

    describe 'when the body is invalid', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/travis-ci'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            'Travis-Repo-Slug': 'hi'
            'Authorization': @travisAuth.encryptOrg('hi')
          form:
            payload: {}

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 400', ->
        expect(@response.statusCode).to.equal 400

    describe 'when the auth uses the pro token', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/travis-ci'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            'Travis-Repo-Slug': 'hi'
            'Authorization': @travisAuth.encryptPro('hi')
          form:
            payload:
              status: 1
              branch: 'v1.0.0'
              repository:
                name: 'the-service'
                owner_name: 'the-owner'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

    describe 'when the deployment does NOT exist', ->
      beforeEach (done) ->
        options =
          uri: '/deployments/travis-ci'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            'Travis-Repo-Slug': 'hi'
            'Authorization': @travisAuth.encryptOrg('hi')
          form:
            payload:
              status: 1
              branch: 'v1.0.0'
              repository:
                name: 'the-service'
                owner_name: 'the-owner'

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

      describe 'when the database record is checked', ->
        beforeEach (done) ->
          query = { owner: 'the-owner', repo: 'the-service', tag: 'v1.0.0' }
          @db.deployments.findOne query, (error, @record) => done error

        it 'should be have the repo', ->
          expect(@record.repo).to.equal 'the-service'

        it 'should be have the owner', ->
          expect(@record.owner).to.equal 'the-owner'

        it 'should be have the tag', ->
          expect(@record.tag).to.equal 'v1.0.0'

        it 'should be NOT be passing', ->
          expect(@record.build.passing).to.be.false

        it 'should have a travis-ci set to passed', ->
          expect(@record.build["travis-ci"].passing).to.be.true

        it 'should have a valid created at date for travis', ->
          expect(moment(@record.build["travis-ci"].createdAt).isBefore(moment())).to.be.true
          expect(moment(@record.build["travis-ci"].createdAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

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
              "docker": {
                passing: true
              }
            }
            cluster: {}
          @db.deployments.insert deployment, done

        beforeEach (done) ->
          options =
            uri: '/deployments/travis-ci'
            baseUrl: "http://localhost:#{@serverPort}"
            headers:
              'Travis-Repo-Slug': 'hi'
              'Authorization': @travisAuth.encryptOrg('hi')
            form:
              payload:
                status: 1
                branch: 'v1.0.0'
                repository:
                  name: 'the-service'
                  owner_name: 'the-owner'

          request.post options, (error, @response, @body) => done error

        it 'should return a 204', ->
          expect(@response.statusCode).to.equal 204

        describe 'when the database record is checked', ->
          beforeEach (done) ->
            query = { owner: 'the-owner', repo: 'the-service', tag: 'v1.0.0' }
            @db.deployments.findOne query, (error, @record) => done error

          it 'should be passing', ->
            expect(@record.build.passing).to.be.true

          it 'should have a travis-ci set to passed', ->
            expect(@record.build["travis-ci"].passing).to.be.true

          it 'should have a valid created at date for travis', ->
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
              passing: false,
              "docker": {
                passing: true
              }
              "travis-ci": {
                passing: false
              }
            }
            cluster: {}
          @db.deployments.insert deployment, done

        describe 'when the webhook is passing', ->
          beforeEach (done) ->
            options =
              uri: '/deployments/travis-ci'
              baseUrl: "http://localhost:#{@serverPort}"
              headers:
                'Travis-Repo-Slug': 'hi'
                'Authorization': @travisAuth.encryptOrg('hi')
              form:
                payload:
                  status: 1
                  branch: 'v1.0.0'
                  repository:
                    name: 'the-service'
                    owner_name: 'the-owner'

            request.post options, (error, @response, @body) =>
              done error

          it 'should return a 204', ->
            expect(@response.statusCode).to.equal 204

          describe 'when the database record is checked', ->
            beforeEach (done) ->
              query = { owner: 'the-owner', repo: 'the-service', tag: 'v1.0.0' }
              @db.deployments.findOne query, (error, @record) =>
                done error

            it 'should be passing', ->
              expect(@record.build.passing).to.be.true

            it 'should have a docker set to passed', ->
              expect(@record.build["travis-ci"].passing).to.be.true

            it 'should have a valid created at date for travis-ci', ->
              expect(moment(@record.build["travis-ci"].createdAt).isBefore(moment())).to.be.true
              expect(moment(@record.build["travis-ci"].createdAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

        describe 'when the webhook is not a tag commit', ->
          beforeEach (done) ->
            options =
              uri: '/deployments/travis-ci'
              baseUrl: "http://localhost:#{@serverPort}"
              headers:
                'Travis-Repo-Slug': 'hi'
                'Authorization': @travisAuth.encryptOrg('hi')
              form:
                payload:
                  status: 1
                  branch: 'master'
                  repository:
                    name: 'the-service'
                    owner_name: 'the-owner'

            request.post options, (error, @response, @body) =>
              done error

          it 'should return a 422', ->
            expect(@response.statusCode).to.equal 422

        describe 'when the webhook is failed', ->
          beforeEach (done) ->
            options =
              uri: '/deployments/travis-ci'
              baseUrl: "http://localhost:#{@serverPort}"
              headers:
                'Travis-Repo-Slug': 'hi'
                'Authorization': @travisAuth.encryptOrg('hi')
              form:
                payload:
                  status: 0
                  branch: 'v1.0.0'
                  repository:
                    name: 'the-service'
                    owner_name: 'the-owner'

            request.post options, (error, @response, @body) =>
              done error

          it 'should return a 204', ->
            expect(@response.statusCode).to.equal 204

          describe 'when the database record is checked', ->
            beforeEach (done) ->
              query = { owner: 'the-owner', repo: 'the-service', tag: 'v1.0.0' }
              @db.deployments.findOne query, (error, @record) =>
                done error

            it 'should be passing', ->
              expect(@record.build.passing).to.be.false

            it 'should have a travis-ci set to failed', ->
              expect(@record.build["travis-ci"].passing).to.be.false

            it 'should have a valid created at date for travis-ci', ->
              expect(moment(@record.build["travis-ci"].createdAt).isBefore(moment())).to.be.true
              expect(moment(@record.build["travis-ci"].createdAt).isAfter(moment().subtract(1, 'minute'))).to.be.true

