require 'harmony-reflect'
isEqual = require 'tantamount'
{Emitter} = require 'emissary'
PropertyAccessors = require 'property-accessors'

module.exports =
class Sequence extends Array
  Emitter.includeInto(this)
  PropertyAccessors.includeInto(this)

  suppressChangeEvents: false

  @fromArray: (array) ->
    array = array.slice()
    array.__proto__ = @prototype
    array.__boundMethods__ = {}
    return Proxy(array, SequenceProxyHandler)

  constructor: (elements...) ->
    return Sequence.fromArray(elements)

  set: (index, value) ->
    if index >= @length
      oldLength = @length
      removedValues = []
      @[index] = value
      insertedValues = @[oldLength..index + 1]
      index = oldLength
    else
      removedValues = [@[index]]
      insertedValues = [value]
      @[index] = value

    @emitChanged {index, removedValues, insertedValues}

  splice: (index, count, insertedValues...) ->
    removedValues = super
    @emitChanged {index, removedValues, insertedValues}
    removedValues

  push: (insertedValues...) ->
    index = @length
    @suppressChangeEvents = true
    result = super
    @suppressChangeEvents = false
    @emitChanged {index, removedValues: [], insertedValues}
    result

  pop: ->
    @suppressChangeEvents = true
    result = super
    @suppressChangeEvents = false
    @emitChanged {index: @length, removedValues: [result], insertedValues: []}
    result

  unshift: (insertedValues...) ->
    @suppressChangeEvents = true
    result = super
    @suppressChangeEvents = false
    @emitChanged {index: 0, removedValues: [], insertedValues}
    result

  shift: ->
    @suppressChangeEvents = true
    result = super
    @suppressChangeEvents = false
    @emitChanged {index: 0, removedValues: [result], insertedValues: []}
    result

  isEqual: (other) ->
    (this is other) or isEqual((v for v in this), (v for v in other))

  onEach: (callback) ->
    @forEach(callback)
    @on 'changed', ({index, insertedValues}) ->
      for value, i in insertedValues
        callback(value, index + i)

  onRemoval: (callback) ->
    @on 'changed', ({index, removedValues}) ->
      for value in removedValues
        callback(value, index)

  @::lazyAccessor '$length', ->
    @signal('changed').map(=> @length).distinctUntilChanged().toBehavior(@length)

  setLength: (length) ->
    if length < @length
      index = length
      removedValues = @[index..]
      insertedValues = []
      @length = length
      @emitChanged {index, removedValues, insertedValues}
    else if length > @length
      index = @length
      removedValues = []
      @length = length
      insertedValues = @[index..]
      @emitChanged {index, removedValues, insertedValues}

  emitChanged: (event) ->
    @emit 'changed', event unless @suppressChangeEvents

# Some array methods segfault the VM if they are called on a proxy rather than a
# true array object. To guard aginst this, the proxy will return a function
# that's bound to the sequence itself for any property on the array prototype.
ArrayMethods = {}
for name in Object.getOwnPropertyNames(Array::)
  ArrayMethods[name] = true if typeof Array::[name] is 'function'

SequenceProxyHandler =
  set: (target, name, value) ->
    if name is 'length'
      target.setLength(value)
    else
      index = parseInt(name)
      if isNaN(index)
        target[name] = value
      else
        target.set(index, value)

  get: (target, name) ->
    if ArrayMethods[name]
      target.__boundMethods__[name] ?= target[name].bind(target)
    else
      target[name]
