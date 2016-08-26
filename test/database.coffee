mongojs = require 'mongojs'

class Database
  constructor: ->
    @database = mongojs 'deploy-state-service-test', ['deployments', 'webhooks']
    @deployments = @database.deployments
    @webhooks = @database.webhooks

  drop: (done) =>
    @webhooks.drop =>
      @deployments.drop =>
        done()

module.exports = Database
