{Behavior, Subscriber, Emitter} = require 'emissary'
PropertyAccessors = require 'property-accessors'
Delegator = require 'delegato'

nextInstanceId = 1

module.exports =
class Model
  Subscriber.includeInto(this)
  Emitter.includeInto(this)
  PropertyAccessors.includeInto(this)
  Delegator.includeInto(this)

  @resetNextInstanceId: -> nextInstanceId = 1

  @properties: (args...) ->
    if typeof args[0] is 'object'
      @property name, defaultValue for name, defaultValue of args[0]
    else
      @property arg for arg in args

  @property: (name, defaultValue) ->
    @declaredProperties ?= {}
    @declaredProperties[name] = defaultValue

    @::accessor name,
      get: -> @get(name)
      set: (value) -> @set(name, value)

    @::accessor "$#{name}",
      get: -> @behavior(name)

  @behavior: (name, definition) ->
    @declaredBehaviors ?= {}
    @declaredBehaviors[name] = definition

    @::accessor name,
      get: -> @behavior(name).getValue()

    @::accessor "$#{name}",
      get: -> @behavior(name)

  @hasDeclaredProperty: (name) ->
    @declaredProperties?.hasOwnProperty(name)

  @hasDeclaredBehavior: (name) ->
    @declaredBehaviors?.hasOwnProperty(name)

  @evaluateDeclaredBehavior: (name, instance) ->
    @declaredBehaviors[name].call(instance)

  declaredPropertyValues: null
  behaviors: null
  alive: true

  constructor: (params) ->
    @assignId(params?.id)
    for propertyName of @constructor.declaredProperties
      if params?.hasOwnProperty(propertyName)
        @set(propertyName, params[propertyName])
      else
        @setDefault(propertyName) unless @get(propertyName, true)?

  assignId: (id) ->
    @id ?= id ? nextInstanceId++

  setDefault: (name) ->
    defaultValue = @constructor.declaredProperties?[name]
    defaultValue = defaultValue.call(this) if typeof defaultValue is 'function'
    @set(name, defaultValue)

  get: (name, suppressDefault) ->
    if @constructor.hasDeclaredProperty(name)
      @declaredPropertyValues ?= {}
      @setDefault(name) unless suppressDefault or @declaredPropertyValues.hasOwnProperty(name)
      @declaredPropertyValues[name]
    else
      @[name]

  set: (name, value) ->
    if typeof name is 'object'
      properties = name
      @set(name, value) for name, value of properties
      properties
    else
      unless @get(name, true) is value
        if @constructor.hasDeclaredProperty(name)
          @declaredPropertyValues ?= {}
          @declaredPropertyValues[name] = value
        else
          @[name] = value
        @behaviors?[name]?.emitValue(value)
      value

  @::advisedAccessor 'id',
    set: (id) -> nextInstanceId = id + 1 if id >= nextInstanceId

  behavior: (name) ->
    @behaviors ?= {}
    if behavior = @behaviors[name]
      behavior
    else
      if @constructor.hasDeclaredProperty(name)
        @behaviors[name] = new Behavior(@get(name)).retain()
      else if @constructor.hasDeclaredBehavior(name)
        @behaviors[name] = @constructor.evaluateDeclaredBehavior(name, this).retain()

  when: (signal, action) ->
    @subscribe signal, (value) =>
      if value
        if typeof action is 'function'
          action.call(this)
        else
          this[action]()

  destroy: ->
    return unless @isAlive()
    @alive = false
    @destroyed?()
    @unsubscribe()
    behavior.release() for name, behavior of @behaviors
    @emit 'destroyed'

  isAlive: -> @alive

  isDestroyed: -> not @isAlive()
