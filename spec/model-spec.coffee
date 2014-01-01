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
      model.foo = 20

      expect(fooValues).toEqual [1, 10, 20]
      expect(barValues).toEqual [2, 21]

  describe "::destroy()", ->
    it "marks the model as no longer alive, unsubscribes, calls an optional destroyed hook, and emits a 'destroyed' event", ->
      class TestModel extends Model
        destroyed: -> @destroyedCalled = true

      emitter = new Model
      model = new TestModel
      model.subscribe emitter, 'foo', ->
      model.on 'destroyed', destroyedHandler = jasmine.createSpy("destroyedHandler")

      expect(model.isAlive()).toBe true
      expect(model.isDestroyed()).toBe false
      expect(emitter.getSubscriptionCount()).toBe 1

      model.destroy()

      expect(model.isAlive()).toBe false
      expect(model.isDestroyed()).toBe true
      expect(model.destroyedCalled).toBe true
      expect(destroyedHandler.callCount).toBe 1
      expect(emitter.getSubscriptionCount()).toBe 0
