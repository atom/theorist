require 'harmony-reflect'
isEqual = require 'tantamount'
{Emitter} = require 'emissary'

module.exports =
class Sequence extends Array
  Emitter.includeInto(this)

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

    @emit 'changed', {index, removedValues, insertedValues}

  splice: (index, count, insertedValues...) ->
    removedValues = super
    @emit 'changed', {index, removedValues, insertedValues}
    removedValues

  setLength: (length) ->
    if length < @length
      index = length
      removedValues = @[index..]
      insertedValues = []
      @length = length
      @emit 'changed', {index, removedValues, insertedValues}
    else if length > @length
      index = @length
      removedValues = []
      @length = length
      insertedValues = @[index..]
      @emit 'changed', {index, removedValues, insertedValues}

  isEqual: (other) ->
    (this is other) or isEqual((v for v in this), (v for v in other))

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
