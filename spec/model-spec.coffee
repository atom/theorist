Model = require '../src/model'

describe "Model", ->
  describe "declared properties", ->
    it "assigns declared properties in the default constructor", ->
      class TestModel extends Model
        @properties 'foo', 'bar'

      model = new TestModel(foo: 1, bar: 2, baz: 3)
      expect(model.foo).toBe 1
      expect(model.bar).toBe 2
      expect(model.baz).toBeUndefined()

    it "allows declared properties to be associated with default values, which are assigned on construction", ->
      class TestModel extends Model
        @properties
          foo: 1
          bar: 2
          baz: -> defaultValue

      defaultValue = 3
      model = new TestModel(foo: 4)
      defaultValue = 10
      expect(model.foo).toBe 4
      expect(model.bar).toBe 2
      expect(model.baz).toBe 3

    it "evaluates default values lazily if the constructor is overridden", ->
      class TestModel extends Model
        @properties
          foo: -> defaultValue

        constructor: ->

      defaultValue = 1
      model = new TestModel
      defaultValue = 2
      expect(model.foo).toBe 2
