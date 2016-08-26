request       = require 'request'
mongojs       = require 'mongojs'
moment        = require 'moment'
shmock        = require 'shmock'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'

describe 'Update And Trigger Webhook', ->
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

  describe 'on PUT /deployments/:owner/:repo/:tag/build/:state/passed', ->
    describe 'when the deployment exists', ->
      beforeEach (done) ->
        @webhooks.insert [
          { url: "http://localhost:#{0xbabe}/trigger1", token: 'trigger-1-secret' }
          { url: "http://localhost:#{0xbabe}/trigger2", token: 'trigger-2-secret' }
        ], done

      beforeEach (done) ->
        record =
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
        @deployments.insert record, done

      beforeEach (done) ->
        deployment =
          tag:  'v1.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          createdAt: moment('2001-01-01').valueOf()
          build: {
            "travis-ci": {
              passing: true,
              updatedAt: moment('2002-02-02').valueOf()
              createdAt: moment('2001-01-01').valueOf()
            }
          }
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
          uri: '/deployments/the-owner/the-service/v1.0.0/build/travis-ci/passed'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
          json: true
          qs:
            date: moment('2002-02-02').valueOf()

        request.put options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

      it 'should trigger the first webhook', ->
        @trigger1.done()

      it 'should trigger the second webhook', ->
        @trigger2.done()

    describe 'when the webhook returns a non-204', ->
      beforeEach (done) ->
        @webhooks.insert [
          { url: "http://localhost:#{0xbabe}/trigger", token: 'trigger-secret' }
        ], done

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
        @deployments.insert deployment, done

      beforeEach (done) ->
        deployment =
          tag:  'v1.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          createdAt: moment('2001-01-01').valueOf()
          build: {
            "travis-ci": {
              passing: true,
              updatedAt: moment('2002-02-02').valueOf()
              createdAt: moment('2001-01-01').valueOf()
            }
          }
          cluster: {}

        @trigger1 = @webhookClient.post('/trigger')
          .set 'Authorization', 'token trigger-secret'
          .send deployment
          .reply(503)

        @trigger2 = @webhookClient.post('/trigger')
          .set 'Authorization', 'token trigger-secret'
          .send deployment
          .reply(422)

        @trigger3 = @webhookClient.post('/trigger')
          .set 'Authorization', 'token trigger-secret'
          .send deployment
          .reply(204)

        options =
          uri: '/deployments/the-owner/the-service/v1.0.0/build/travis-ci/passed'
          baseUrl: "http://localhost:#{@serverPort}"
          headers:
            Authorization: 'token deploy-state-key'
          json: true
          qs:
            date: moment('2002-02-02').valueOf()

        request.put options, (error, @response, @body) =>
          done error

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

      it 'should retry the first webhook', ->
        @trigger1.done()

      it 'should retry the second webhook', ->
        @trigger2.done()

      it 'should retry the third webhook', ->
        @trigger3.done()
