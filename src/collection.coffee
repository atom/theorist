require 'harmony-reflect'
isEqual = require 'tantamount'
{Emitter} = require 'emissary'

module.exports =
class Collection extends Array
  Emitter.includeInto(this)

  constructor: (elements...) ->
    elements.__proto__ = Collection.prototype
    return Proxy(elements, CollectionProxyHandler)

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

  isEqual: (other) ->
    (this is other) or isEqual((v for v in this), (v for v in other))

CollectionProxyHandler =
  set: (target, name, value) ->
    index = parseInt(name)
    if isNaN(index)
      target[name] = value
    else
      target.set(index, value)
