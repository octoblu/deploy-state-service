request       = require 'request'
Database      = require '../database'
moment        = require 'moment'
shmock        = require 'shmock'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'

describe 'Update And Trigger Webhook', ->
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

    serverOptions.database = @db.database

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
        auth = { username: 'uuid', password: 'token' }
        @db.webhooks.insert [
          { url: "http://localhost:#{0xbabe}/trigger", events: ['create'], auth }
          { url: "http://localhost:#{0xbabe}/trigger1", auth }
          { url: "http://localhost:#{0xbabe}/trigger2", auth }
        ], done

      beforeEach (done) ->
        record =
          tag:  'v1.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          createdAt: moment('2001-01-01').toDate()
          build: {
            passing: false,
            "travis-ci": {
              passing: false,
              createdAt: moment('2001-01-01').toDate()
            }
          }
          cluster: {}
        @db.deployments.insert record, done

      beforeEach (done) ->
        deployment =
          tag:  'v1.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          createdAt: moment('2001-01-01').valueOf()
          build: {
            passing: false,
            "travis-ci": {
              passing: true,
              updatedAt: moment('2002-02-02').valueOf()
              createdAt: moment('2001-01-01').valueOf()
            }
          }
          cluster: {}

        @trigger = @webhookClient.put('/trigger')
          .set 'Authorization', 'Basic ' + new Buffer('uuid:token').toString('base64')
          .send deployment
          .reply(204)

        @trigger1 = @webhookClient.put('/trigger1')
          .set 'Authorization', 'Basic ' + new Buffer('uuid:token').toString('base64')
          .send deployment
          .reply(204)

        @trigger2 = @webhookClient.put('/trigger2')
          .set 'Authorization', 'Basic ' + new Buffer('uuid:token').toString('base64')
          .send deployment
          .reply(204)

        options =
          uri: '/deployments/the-owner/the-service/v1.0.0/build/travis-ci/passed'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
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

      it 'should not trigger the create only webhook', ->
        expect(@trigger.isDone).to.be.false

    describe 'when the webhook returns a non-2xx', ->
      beforeEach (done) ->
        @db.webhooks.insert [
          { url: "http://localhost:#{0xbabe}/trigger", auth: { username: 'uuid', password: 'token' } }
          { url: "http://localhost:#{0xbabe}/trigger-success", auth: { username: 'uuid', password: 'token' } }
        ], done

      beforeEach (done) ->
        deployment =
          tag:  'v1.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          createdAt: moment('2001-01-01').toDate()
          build: {
            passing: false,
            "travis-ci": {
              passing: false,
              createdAt: moment('2001-01-01').toDate()
            }
            docker: {
              passing: true
            }
          }
          cluster: {}
        @db.deployments.insert deployment, done

      beforeEach (done) ->
        deployment =
          tag:  'v1.0.0'
          repo: 'the-service'
          owner: 'the-owner'
          createdAt: moment('2001-01-01').valueOf()
          build: {
            passing: true,
            "travis-ci": {
              passing: true,
              updatedAt: moment('2002-02-02').valueOf()
              createdAt: moment('2001-01-01').valueOf()
            }
            "docker": {
              passing: true
            }
          }
          cluster: {}

        @trigger1 = @webhookClient.put('/trigger')
          .set 'Authorization', 'Basic ' + new Buffer('uuid:token').toString('base64')
          .send deployment
          .reply(503)

        @trigger2 = @webhookClient.put('/trigger')
          .set 'Authorization', 'Basic ' + new Buffer('uuid:token').toString('base64')
          .send deployment
          .reply(422)

        @trigger3 = @webhookClient.put('/trigger')
          .set 'Authorization', 'Basic ' + new Buffer('uuid:token').toString('base64')
          .send deployment
          .reply(404)

        @triggerSuccess = @webhookClient.put('/trigger-success')
          .set 'Authorization', 'Basic ' + new Buffer('uuid:token').toString('base64')
          .send deployment
          .reply(204)

        options =
          uri: '/deployments/the-owner/the-service/v1.0.0/build/travis-ci/passed'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'username'
            password: 'password'
          json: true
          qs:
            date: moment('2002-02-02').valueOf()

        request.put options, (error, @response, @body) =>
          done error

      it 'should return a 204 and hit up the webhook 3 times and the success webhook', ->
        expect(@response.statusCode).to.equal 204
        @trigger1.done()
        @trigger2.done()
        @trigger3.done()
        @triggerSuccess.done()

