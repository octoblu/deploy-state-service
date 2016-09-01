request       = require 'request'
moment        = require 'moment'
shmock        = require 'shmock'
enableDestroy = require 'server-destroy'
Database      = require '../database'
Server        = require '../../src/server'

describe 'Create Deployment and Trigger Webhooks', ->
  beforeEach (done) ->
    @db = new Database
    @db.drop done

  beforeEach (done) ->
    @logFn = sinon.spy()

    @webhookClient = shmock 0xbabe
    enableDestroy @webhookClient

    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      username: 'username'
      password: 'password'
      travisToken: 'hello'

    serverOptions.database = @db.database

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()
    @webhookClient.destroy()

  describe 'on POST /deployments/:owner/:repo/:tag', ->
    beforeEach (done) ->
      @db.webhooks.insert [
        { url: "http://localhost:#{0xbabe}/trigger1", auth: { username: 'uuid', password: 'token' } }
        { url: "http://localhost:#{0xbabe}/trigger2", auth: { username: 'uuid', password: 'token' } }
      ], done

    describe 'when does not exist', ->
      beforeEach (done) ->
        deployment =
          repo: 'the-service'
          owner: 'the-owner'
          tag: 'v1.0.0'
          createdAt: moment('2002-02-02').valueOf()
          build: { passing: false }
          cluster: {}

        @trigger1 = @webhookClient.post('/trigger1')
          .set 'Authorization', 'Basic ' + new Buffer('uuid:token').toString('base64')
          .send deployment
          .reply(201)

        @trigger2 = @webhookClient.post('/trigger2')
          .set 'Authorization', 'Basic ' + new Buffer('uuid:token').toString('base64')
          .send deployment
          .reply(201)

        options =
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json: true
          qs:
            date: moment('2002-02-02').valueOf()

        request.post options, (error, @response, @body) =>
          done error

      it 'should return a 201', ->
        expect(@response.statusCode).to.equal 201

      it 'should have a "Created"', ->
        expect(@body).to.equal 'Created'

      it 'should trigger the first webhook', ->
        @trigger1.done()

      it 'should trigger the second webhook', ->
        @trigger2.done()

      describe 'when the database record is checked', ->
        beforeEach (done) ->
          query = { owner: 'the-owner', repo: 'the-service', tag: 'v1.0.0' }
          @db.deployments.findOne query, (error, @record) =>
            done error

        it 'should have a valid created at date', ->
          expect(moment(@record.createdAt).valueOf()).to.equal moment('2002-02-02').valueOf()

        it 'should have a non-passing build', ->
          expect(@record.build).to.deep.equal { passing: false }

        it 'should have an empty cluster', ->
          expect(@record.cluster).to.deep.equal {}

      describe 'when it is called again', ->
        beforeEach (done) ->
          options =
            uri: '/deployments/the-owner/the-service/v1.0.0'
            baseUrl: "http://localhost:#{@serverPort}"
            auth:
              username: 'username'
              password: 'password'
            json: true

          request.post options, (error, @response, @body) =>
            done error

        it 'should return a 204', ->
          expect(@response.statusCode).to.equal 204

        it 'should no body', ->
          expect(@body).to.be.empty

