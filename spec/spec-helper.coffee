require 'coffee-cache'
jasmine.getEnv().addEqualityTester(require 'tantamount')

Model = require '../src/model'
beforeEach -> Model.resetNextInstanceId()
