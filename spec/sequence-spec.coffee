Sequence = require '../src/sequence'

describe "Sequence", ->
  [sequence, changes] = []

  beforeEach ->
    sequence = Sequence("abcdefg".split('')...)
    changes = []
    sequence.on 'changed', (change) -> changes.push(change)

  it "reports itself as an instance of both Sequence and Array", ->
    expect(sequence instanceof Sequence).toBe true
    expect(sequence instanceof Array).toBe true

  describe ".fromArray", ->
    it "constructs a sequence from the given array", ->
      expect(Sequence.fromArray(['a', 'b', 'c'])).toEqual ['a', 'b', 'c']

  describe "property access via ::[]", ->
    it "allows sequence elements to be read via numeric keys", ->
      expect(sequence[0]).toBe 'a'
      expect(sequence['1']).toBe 'b'

    # This can be enabled when harmony proxies are stable when proxying arrays
    xit "updates the sequence and emits 'changed' events when assigning elements via numeric keys", ->
      sequence[2] = 'C'
      expect(sequence).toEqual "abCdefg".split('')
      expect(changes).toEqual [{
        index: 2
        removedValues: ['c']
        insertedValues: ['C']
      }]

      changes = []
      sequence[9] = 'X'
      expect(sequence).toEqual "abCdefg".split('').concat([undefined, undefined, 'X'])
      expect(changes).toEqual [{
        index: 7
        removedValues: []
        insertedValues: [undefined, undefined, 'X']
      }]

    it "allows non-numeric properties to be accessed via non-numeric keys", ->
      sequence.foo = "bar"
      expect(sequence.foo).toBe "bar"

  describe "::length", ->
    it "returns the current length of the sequence", ->
      expect(sequence.length).toBe 7

    # This can be enabled when harmony proxies are stable when proxying arrays
    xdescribe "when assigning a value shorter than the current length", ->
      it "truncates the sequence and emits a 'changed' event", ->
        sequence.length = 4
        expect(sequence).toEqual "abcd".split('')
        expect(changes).toEqual [{
          index: 4
          removedValues: ['e', 'f', 'g']
          insertedValues: []
        }]

    # This can be enabled when harmony proxies are stable when proxying arrays
    xdescribe "when assigning a value greater than the current length", ->
      it "expands the sequence and emits a 'changed' event'", ->
        sequence.length = 9
        expect(sequence).toEqual "abcdefg".split('').concat([undefined, undefined])
        expect(changes).toEqual [{
          index: 7
          removedValues: []
          insertedValues: [undefined, undefined]
        }]

  describe "::$length", ->
    it "returns a behavior based on the current length of the array", ->
      lengths = []
      sequence.$length.onValue (l) -> lengths.push(l)

      expect(lengths).toEqual [7]
      sequence.push('X')
      sequence.splice(2, 3, 'Y')
      sequence.splice(0, 1, 'Z')
      expect(lengths).toEqual [7, 8, 6]

  describe "iteration", ->
    it "can iterate over the sequence with standard coffee-script syntax", ->
      values = (value for value in sequence)
      expect(values).toEqual sequence

  describe "::splice", ->
    it "splices the sequence and emits a 'changed' event", ->
      result = sequence.splice(3, 2, 'D', 'E', 'F')
      expect(result).toEqual ['d', 'e']
      expect(sequence).toEqual "abcDEFfg".split('')
      expect(changes).toEqual [{
        index: 3
        removedValues: ['d', 'e']
        insertedValues: ['D', 'E', 'F']
      }]

  describe "::push", ->
    it "pushes to the sequence and emits a 'changed' event", ->
      result = sequence.push('X', 'Y', 'Z')
      expect(result).toBe 10
      expect(sequence).toEqual "abcdefgXYZ".split('')
      expect(changes).toEqual [{
        index: 7
        removedValues: []
        insertedValues: ['X', 'Y', 'Z']
      }]

  describe "::pop", ->
    it "pops the sequence and emits a 'changed' event", ->
      result = sequence.pop()
      expect(result).toBe 'g'
      expect(sequence).toEqual "abcdef".split('')
      expect(changes).toEqual [{
        index: 6
        removedValues: ['g']
        insertedValues: []
      }]

  describe "::unshift", ->
    it "unshifts to the sequence and emits a 'changed' event", ->
      result = sequence.unshift('X', 'Y', 'Z')
      expect(result).toBe 10
      expect(sequence).toEqual "XYZabcdefg".split('')
      expect(changes).toEqual [{
        index: 0
        removedValues: []
        insertedValues: ['X', 'Y', 'Z']
      }]

  describe "::shift", ->
    it "shifts from the sequence and emits a 'changed' event", ->
      result = sequence.shift()
      expect(result).toBe 'a'
      expect(sequence).toEqual "bcdefg".split('')
      expect(changes).toEqual [{
        index: 0
        removedValues: ['a']
        insertedValues: []
      }]

  describe "::onEach", ->
    it "calls the given callback for all current and future elements in the array", ->
      values = []
      indices = []
      sequence.onEach (v, i) -> values.push(v); indices.push(i)
      expect(values).toEqual "abcdefg".split('')
      expect(indices).toEqual [0..6]

      values = []
      indices = []

      sequence.push('H', 'I')
      sequence.splice(2, 2, 'X')
      expect(values).toEqual ['H', 'I', 'X']
      expect(indices).toEqual [7, 8, 2]

  describe "::onRemoval", ->
    it "calls the given callback with each element that's removed from the array", ->
      values = []
      indices = []
      sequence.onRemoval (v, i) -> values.push(v); indices.push(i)
      sequence.splice(2, 2, 'X')
      sequence.splice(5, 1)
      expect(values).toEqual ['c', 'd', 'g']
      expect(indices).toEqual [2, 2, 5]
