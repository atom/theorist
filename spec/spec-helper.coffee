require 'coffee-cache'
jasmine.getEnv().addEqualityTester(require('underscore-plus').isEqual)

Model = require '../src/model'
beforeEach -> Model.resetNextInstanceId()
