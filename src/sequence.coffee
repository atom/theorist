require 'harmony-reflect'
isEqual = require 'tantamount'
{Emitter} = require 'emissary'

module.exports =
class Sequence extends Array
  Emitter.includeInto(this)

  suppressChangeEvents: false

  constructor: (elements...) ->
    elements.__proto__ = Sequence.prototype
    return Proxy(elements, SequenceProxyHandler)

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

  isEqual: (other) ->
    (this is other) or isEqual((v for v in this), (v for v in other))

  emitChanged: (event) ->
    @emit 'changed', event unless @suppressChangeEvents

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
    # ::splice must be bound to actual target to avoid segfaults
    if name is 'splice'
      target.splice.bind(target)
    else
      target[name]
