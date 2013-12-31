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

    it "associates declared properties with $-prefixed behavior accessors", ->
      class TestModel extends Model
        @properties 'foo', 'bar'

      model = new TestModel(foo: 1, bar: 2)

      fooValues = []
      barValues = []
      model.$foo.onValue (v) -> fooValues.push(v)
      model.$bar.onValue (v) -> barValues.push(v)

      model.foo = 10
      model.set(foo: 20, bar: 21)

      # expect(fooValues).toEqual [1, 10, 20]
      expect(barValues).toEqual [2, 21]
