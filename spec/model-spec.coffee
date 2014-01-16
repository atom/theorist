{Behavior, Signal} = require 'emissary'
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

    it "does not assign default values over existing values", ->
      class TestModel extends Model
        bar: 3
        @properties
          foo: 1
          bar: 2

      model = Object.create(TestModel.prototype)
      model.bar = 3
      TestModel.call(model)
      expect(model.foo).toBe 1
      expect(model.bar).toBe 3

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

  describe ".behavior", ->
    it "defines behavior accessors based on the given name and definition", ->
      class TestModel extends Model
        @property 'foo', 0
        @behavior 'bar', -> @$foo.map (v) -> v + 1

      model = new TestModel

      expect(model.bar).toBe 1
      values = []
      model.$bar.onValue (v) -> values.push(v)

      model.foo = 10
      expect(model.bar).toBe 11
      expect(values).toEqual [1, 11]

    it "releases behaviors when the model is destroyed", ->
      behavior = new Behavior(0)
      class TestModel extends Model
        @property 'foo', 0
        @behavior 'bar', -> behavior

      model = new TestModel
      model.bar # force retention of behavior

      expect(behavior.retainCount).toBeGreaterThan 0
      model.destroy()
      expect(behavior.retainCount).toBe 0

  describe "instance ids", ->
    it "assigns a unique id to each model instance", ->
      model1 = new Model
      model2 = new Model

      expect(model1.id).toBeDefined()
      expect(model2.id).toBeDefined()
      expect(model1.id).not.toBe model2.id

    it "honors explicit id assignments in the params hash", ->
      model1 = new Model(id: 22)
      model2 = new Model(id: 33)
      expect(model1.id).toBe 22
      expect(model2.id).toBe 33

      # auto-generates a higher id than what was explicitly assigned
      model3 = new Model
      expect(model3.id).toBe 34

  describe "::destroy()", ->
    it "marks the model as no longer alive, unsubscribes, calls an optional destroyed hook, and emits a 'destroyed' event", ->
      class TestModel extends Model
        destroyedCallCount: 0
        destroyed: -> @destroyedCallCount++

      emitter = new Model
      model = new TestModel
      model.subscribe emitter, 'foo', ->
      model.on 'destroyed', destroyedHandler = jasmine.createSpy("destroyedHandler")

      expect(model.isAlive()).toBe true
      expect(model.isDestroyed()).toBe false
      expect(emitter.getSubscriptionCount()).toBe 1

      model.destroy()
      model.destroy()

      expect(model.isAlive()).toBe false
      expect(model.isDestroyed()).toBe true
      expect(model.destroyedCallCount).toBe 1
      expect(destroyedHandler.callCount).toBe 1
      expect(emitter.getSubscriptionCount()).toBe 0

  describe "::when(signal, callback)", ->
    describe "when called with a callback", ->
      it "calls the callback when the signal yields a truthy value", ->
        signal = new Signal
        model = new Model
        model.when signal, callback = jasmine.createSpy("callback").andCallFake -> expect(this).toBe model
        signal.emitValue(0)
        signal.emitValue(null)
        signal.emitValue('')
        expect(callback.callCount).toBe 0
        signal.emitValue(1)
        expect(callback.callCount).toBe 1

    describe "when called with a method name", ->
      it "calls the named method when the signal yields a truthy value", ->
        signal = new Signal
        model = new Model
        model.action = jasmine.createSpy("action")
        model.when signal, 'action'
        signal.emitValue(0)
        signal.emitValue(null)
        signal.emitValue('')
        expect(model.action.callCount).toBe 0
        signal.emitValue(1)
        expect(model.action.callCount).toBe 1
