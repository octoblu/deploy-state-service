request       = require 'request'
mongojs       = require 'mongojs'
moment        = require 'moment'
shmock        = require 'shmock'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'

describe 'Create Deployment and Trigger Webhooks', ->
  beforeEach (done) ->
    @logFn = sinon.spy()

    @webhookClient = shmock 0xbabe
    enableDestroy @webhookClient

    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      deployStateKey: 'deploy-state-key'

    database = mongojs 'deploy-state-service-test', ['deployments', 'webhooks']
    serverOptions.database = database
    @deployments = database.deployments
    @deployments.drop()

    @webhooks = database.webhooks
    @webhooks.drop()

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @server.destroy()
    @webhookClient.destroy()

  describe 'on POST /deployments/:owner/:repo/:tag', ->
    beforeEach (done) ->
      @webhooks.insert [
        { url: "http://localhost:#{0xbabe}/trigger1", token: 'trigger-1-secret' }
        { url: "http://localhost:#{0xbabe}/trigger2", token: 'trigger-2-secret' }
      ], done

    describe 'when does not exist', ->
      beforeEach (done) ->
        deployment =
          repo: 'the-service'
          owner: 'the-owner'
          tag: 'v1.0.0'
          createdAt: moment('2002-02-02').valueOf()
          build: {}
          cluster: {}

        @trigger1 = @webhookClient.post('/trigger1')
          .set 'Authorization', 'token trigger-1-secret'
          .send deployment
          .reply(204)

        @trigger2 = @webhookClient.post('/trigger2')
          .set 'Authorization', 'token trigger-2-secret'
          .send deployment
          .reply(204)

        options =
          uri: '/deployments/the-owner/the-service/v1.0.0'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
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
          @deployments.findOne query, (error, @record) =>
            done error

        it 'should have a valid created at date', ->
          expect(moment(@record.createdAt).valueOf()).to.equal moment('2002-02-02').valueOf()

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

