shmock        = require 'shmock'
request       = require 'request'
enableDestroy = require 'server-destroy'
Server        = require '../../src/server'

describe 'Get Deployment', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d
    enableDestroy @meshblu

    @logFn = sinon.spy()
    serverOptions =
      port: undefined,
      disableLogging: true
      logFn: @logFn
      deployStateKey: 'deploy-state-key'
      meshbluConfig:
        hostname: 'localhost'
        protocol: 'http'
        resolveSrv: false
        port: 0xd00d

    @server = new Server serverOptions

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach ->
    @meshblu.destroy()
    @server.destroy()

  describe 'On GET /deployments/the-service/v1.0.0', ->
    beforeEach (done) ->
      options =
        uri: '/deployments/the-service/v1.0.0'
        baseUrl: "http://localhost:#{@serverPort}"
        headers: {
          Authorization: 'token deploy-state-key'
        }
        json: true

      request.get options, (error, @response, @body) =>
        done error

    it 'should return a 200', ->
      expect(@response.statusCode).to.equal 200

    it 'should have the service name in the response', ->
      expect(@body.service).to.equal 'the-service'

    it 'should have the tag in the response', ->
      expect(@body.tag).to.equal 'v1.0.0'

    it 'should have the overall state set to green', ->
      expect(@body.state.overall).to.deep.equal {
        color: 'green'
      }

    it 'should have an error count of 0', ->
      expect(@body.state.errors).to.deep.equal {
        count: 0
      }

