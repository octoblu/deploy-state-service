# deploy-state-service

[![Dependency status](http://img.shields.io/david/octoblu/deploy-state-service.svg?style=flat)](https://david-dm.org/octoblu/deploy-state-service)
[![devDependency Status](http://img.shields.io/david/dev/octoblu/deploy-state-service.svg?style=flat)](https://david-dm.org/octoblu/deploy-state-service#info=devDependencies)
[![Build Status](http://img.shields.io/travis/octoblu/deploy-state-service.svg?style=flat)](https://travis-ci.org/octoblu/deploy-state-service)

# Table of Contents

* [Introduction](#introduction)
* [Getting Started](#getting-started)
  * [Install](#install)
* [Usage](#usage)
  * [Default](#default)
  * [Docker](#docker)
    * [Development](#development)
    * [Production](#production)
  * [Debugging](#debugging)
* [Clients](#clients)
* [API](#api)
  * [List Deployments](#list-deployments)
  * [Get Deployment](#get-deployment)
  * [Create Deployment](#create-deployment)
  * [Register Webhook](#register-webhook)
  * [Delete Webhook](#delete-webhook)
  * [Update Build Passed](#update-build-passed)
  * [Update Build Failed](#update-build-failed)
  * [Update Cluster Passed](#update-cluster-passed)
  * [Update Cluster Failed](#update-cluster-failed)
  * [Update From Quay](#update-from-quay)
  * [Update From Travis](#update-from-travis)
* [License](#license)

# Introduction

**Micro-service for deploying micro-services**. It is not tied to any specific deployment architecture, or service. The main purpose of this service is to track whether the build steps, and cluster deployments, are passing or not. It is up to the client to determine whether they should be running a deployment.

# Getting Started

## Install

```bash
git clone https://github.com/octoblu/deploy-state-service.git
cd /path/to/deploy-state-service
npm install
```

# Usage

### Required Environment

```
MONGODB_URI='mongodb://localhost:27017/some-deploy-state-database'
DEPLOY_STATE_USERNAME='the-username'
DEPLOY_STATE_PASSWORD='the-secret'
TRAVIS_TOKEN_ORG='travis-secret-org'
TRAVIS_TOKEN_PRO='travis-secret-pro'
```

## Default

```javascript
node command.js
```

## Debugging

```bash
env DEBUG='deploy-state-service*' node command.js
```

## Docker 

### Development

```bash
docker build -t local/deploy-state-service .
docker run --rm -it --name deploy-state-service-local -p 8888:80 local/deploy-state-service
```

### Production

```bash
docker pull quay.io/octoblu/deploy-state-service
docker run --rm -p 8888:80 quay.io/octoblu/deploy-state-service
```

# API

## Authentication

Use basic auth with a the service's deploy-state username and password.

## List Deployments

`GET /deployments/:owner/:repo`

### Response

```cson
deployments: [
  {
    repo : "weather-service"
    owner: "octoblu"
    tag  : "v1.0.0"
    createdAt: 100000000
    build: {
      passing: true,
      dockerUrl: "quay.io/octoblu/weather-service:v1.0.0"
      "travis-ci": {
        passing: true
        createdAt: 10000000
      }
      "docker": {
        passing: true
        createdAt: 10000000
      }
    }
    cluster: {
      "minor": {
        passing: true
        createdAt: 10000000
      }
    }
  }
]
```

## Get Deployment

`GET /deployments/:owner/:repo/:tag`

### Response

```cson
{
  repo : "weather-service"
  owner: "octoblu"
  tag  : "v1.0.0"
  createdAt: 100000000
  dockerUrl: 'quay.io/octoblu/weather-service:v1.0.0'
  build: {
    passing: true,
    "travis-ci": {
      passing: true
      createdAt: 10000000
    }
    "docker": {
      passing: true
      createdAt: 10000000
    }
  }
  cluster: {
    "minor": {
      passing: true
      createdAt: 10000000
    }
  }
}
```

## Create Deployment

`POST /deployments/:owner/:repo/:tag`

## Register Webhook 

Register a webhook to be triggered everytime a deployment is updated, or created.

`POST /webhooks`

### Body

```json
{
  "url": "https://my.deployment.client.octoblu.com/deployment/changed",
  "events": ["create", "update"],
  "auth": {
    "username": "some-username",
    "password": "some-password"
  }
}
```

When a deployment is created and updated the deploy-state-service will hit the webhook, up to 3 times, until it gets 200 level status code back. 

The webhook's auth username and password will be sent along with the request.

For create the request method is a POST and for update it is PUT.

## Delete Webhook 

`DELETE /webhooks`

### Body

```json
{
  "url": "https://my.deployment.client.octoblu.com/deployment/changed"
}
```

## Update Build Passed 

`PUT /deployments/:owner/:repo/:tag/build/:state/passed`

## Update Build Failed 

`PUT /deployments/:owner/:repo/:tag/build/:state/failed`

## Update Cluster Passed 

`PUT /deployments/:owner/:repo/:tag/cluster/:state/passed`

## Update Cluster Failed 

`PUT /deployments/:owner/:repo/:tag/cluster/:state/failed`

## Update From Quay 

`POST /deployments/quay.io`

## Update From Travis 

### Private Repos

`POST /deployments/travis-ci/pro`

#### Example travis.yml

```yml
notifications:
  webhooks: https://deploy-state.octoblu.com/deployments/travis-ci/pro
```

### Public Repos

`POST /deployments/travis-ci/org`

#### Example travis.yml

```yml
notifications:
  webhooks: https://deploy-state.octoblu.com/deployments/travis-ci/org
```

## License

The MIT License (MIT)

Copyright (c) 2016 Octoblu

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
