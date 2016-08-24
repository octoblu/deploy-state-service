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
          { url: "http://localhost:#{0xbabe}/trigger1" }
          { url: "http://localhost:#{0xbabe}/trigger2" }
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
        @trigger1 = @webhookClient.post('/trigger1').reply(200)
        @trigger2 = @webhookClient.post('/trigger2').reply(200)

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

      it 'should trigger the first webhook', ->
        @trigger1.done()

      it 'should trigger the second webhook', ->
        @trigger2.done()

