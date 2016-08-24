_      = require 'lodash'
async  = require 'async'
moment = require 'moment'

PROJECTION =
  _id:   false
  tag:   true
  owner: true
  repo:  true
  createdAt: true
  build: true
  cluster: true

class DeployStateService
  constructor: ({ database }) ->
    @deployments = database.collection 'deployments'

  getDeployment: ({ owner, repo, tag }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback @_createError(404, 'Unable to find deployment') unless deployment?
      callback null, deployment

  createDeployment: ({ owner, repo, tag }, callback) =>
    @_findDeployment { owner, repo, tag }, (error, deployment) =>
      return callback error if error?
      return callback null, 204 if deployment?
      record = {
        owner,
        repo,
        tag,
        build: {},
        cluster: {},
        createdAt: new Date()
      }
      @deployments.insert record, (error) =>
        return callback error if error?
        callback null, 201

  listDeployments: ({ owner, repo }, callback) =>
    @_findDeployments { owner, repo }, callback

  _findDeployment: ({ owner, repo, tag }, callback) =>
    @deployments.findOne { owner, repo, tag }, PROJECTION, (error, deployment) =>
      return callback error if error?
      return callback null, null unless deployment?
      callback null, @_mapDeployment deployment

  _findDeployments: ({ owner, repo }, callback) =>
    @deployments.find { owner, repo }, PROJECTION, (error, deployments) =>
      return callback error if error?
      callback null, _.map deployments, @_mapDeployment

  _mapDeployment: (deployment) =>
    deployment = @_convertDates deployment
    deployment.build = _.mapValues deployment.build, @_convertDates
    deployment.cluster = _.mapValues deployment.cluster, @_convertDates
    return deployment

  _convertDates: (obj) =>
    obj.createdAt = moment(obj.createdAt).valueOf() if obj.createdAt?
    obj.updatedAt = moment(obj.updatedAt).valueOf() if obj.updatedAt?
    return obj

  _createError: (code, message) =>
    error = new Error message
    error.code = code if code?
    return error

module.exports = DeployStateService
