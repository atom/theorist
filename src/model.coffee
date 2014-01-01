{Behavior, Subscriber, Emitter} = require 'emissary'

module.exports =
class Model
  Subscriber.includeInto(this)
  Emitter.includeInto(this)

  @properties: (args...) ->
    if typeof args[0] is 'object'
      @property name, defaultValue for name, defaultValue of args[0]
    else
      @property arg for arg in args

  @property: (name, defaultValue) ->
    @declaredProperties ?= {}
    @declaredProperties[name] = defaultValue

    Object.defineProperty @prototype, name,
      get: -> @get(name)
      set: (value) -> @set(name, value)

    Object.defineProperty @prototype, "$#{name}",
      get: -> @behavior(name)

  @hasDeclaredProperty: (name) ->
    @declaredProperties?.hasOwnProperty(name)

  declaredPropertyValues: null
  behaviors: null

  constructor: (params) ->
    for propertyName of @constructor.declaredProperties
      if params.hasOwnProperty(propertyName)
        @set(propertyName, params[propertyName])
      else
        @setDefault(propertyName)

  setDefault: (name) ->
    defaultValue = @constructor.declaredProperties?[name]
    defaultValue = defaultValue.call(this) if typeof defaultValue is 'function'
    @set(name, defaultValue)

  get: (name) ->
    if @constructor.hasDeclaredProperty(name)
      @declaredPropertyValues ?= {}
      @setDefault(name) unless @declaredPropertyValues.hasOwnProperty(name)
      @declaredPropertyValues[name]
    else
      @[name]

  set: (name, value) ->
    if typeof name is 'object'
      properties = name
      @set(name, value) for name, value of properties
      properties
    else
      if @constructor.hasDeclaredProperty(name)
        @declaredPropertyValues ?= {}
        @declaredPropertyValues[name] = value
      else
        @[name] = value

      @behaviors?[name]?.emitValue(value)
      value

  behavior: (name) ->
    @behaviors ?= {}
    @behaviors[name] ?= new Behavior(@get(name))
