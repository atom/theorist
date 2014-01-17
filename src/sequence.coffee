{isEqual} = require 'underscore-plus'
{Emitter} = require 'emissary'
PropertyAccessors = require 'property-accessors'

module.exports =
class Sequence extends Array
  Emitter.includeInto(this)
  PropertyAccessors.includeInto(this)

  suppressChangeEvents: false

  @fromArray: (array=[]) ->
    array = array.slice()
    array.__proto__ = @prototype
    array

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
