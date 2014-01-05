Collection = require '../src/collection'

isEqual = require 'tantamount'

describe "Collection", ->
  [collection, changes] = []

  beforeEach ->
    collection = Collection("abcdefg".split('')...)
    changes = []
    collection.on 'changed', (change) -> changes.push(change)

  it "reports itself as an instance of both Collection and Array", ->
    expect(collection instanceof Collection).toBe true
    expect(collection instanceof Array).toBe true

  describe "property access via ::[]", ->
    it "allows collection elements to be read via numeric keys", ->
      expect(collection[0]).toBe 'a'
      expect(collection['1']).toBe 'b'

    it "updates the collection and emits 'changed' events when assigning elements via numeric keys", ->
      collection[2] = 'C'
      expect(collection).toEqual "abCdefg".split('')
      expect(changes).toEqual [{
        index: 2
        removedValues: ['c']
        insertedValues: ['C']
      }]

      changes = []
      collection[9] = 'X'
      expect(collection).toEqual "abCdefg".split('').concat([undefined, undefined, 'X'])
      expect(changes).toEqual [{
        index: 7
        removedValues: []
        insertedValues: [undefined, undefined, 'X']
      }]

    it "allows non-numeric properties to be accessed via non-numeric keys", ->
      collection.foo = "bar"
      expect(collection.foo).toBe "bar"

  describe "::length", ->
    it "returns the current length of the collection", ->
      expect(collection.length).toBe 7

    describe "when assigning a value shorter than the current length", ->
      it "truncates the collection and emits a 'changed' event", ->
        collection.length = 4
        expect(collection).toEqual "abcd".split('')
        expect(changes).toEqual [{
          index: 4
          removedValues: ['e', 'f', 'g']
          insertedValues: []
        }]

    describe "when assigning a value greater than the current length", ->
      it "expands the collection and emits a 'changed' event'", ->
        collection.length = 9
        expect(collection).toEqual "abcdefg".split('').concat([undefined, undefined])
        expect(changes).toEqual [{
          index: 7
          removedValues: []
          insertedValues: [undefined, undefined]
        }]

  describe "iteration", ->
    it "can iterate over the collection with standard coffee-script syntax", ->
      values = (value for value in collection)
      expect(values).toEqual collection
