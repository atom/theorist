# Theorist: A Reactive Model Library

This library supports writing your model layer in a *reactive* style, allowing
the application's response to *state changes* and *events* to be expressed in a
declarative way. It was developed for use in [Atom](https://atom.io) core and is
also used in a few packages. It's still a work in progress and there are many
features to be added, but the core ideas are solid.

Theorist exports two classes, `Model` and `Sequence`. `Model` is a superclass
for model objects with reactive properties, while `Sequence` is an array-like
collection that can be refined into *derived sequences* with relational
operators.

## Models

Conceptually, a `Model` instance is a collection of *properties*, like any
basic JavaScript object. The difference is that declared properties can
automatically be transformed into reactive *behaviors*. A *behavior* is an
object that represents the current and *future* values of a property, allowing
for expressions that retain their meaning across time. Behaviors are provided
by a separate library called [emissary](emissary). A a special kind of `Signal`,
they offer composable abstractions for scalar values that change over time.

### Declaring Properties

To declare properties, use the `Model.properties` class method with multiple
one or more property names or a map of property names to their default values:

```coffee
{Model} = require 'theorist'

class Person extends Model
  @properties
    firstName: 'Jane'
    lastName: 'Doe'
    gender: 'female'
    followerCount: 0
```

The `Model` constructor will automatically assign any declared properties based
on a params hash when instantiating a model object. Omitted properties will be
assigned their default values.

```coffee
alice = new Person(firstName: "Alice")
expect(alice.firstName).toBe "Alice"
expect(alice.lastName).toBe "Doe"
expect(alice.gender).toBe "female"
expect(alice.followerCount).toBe 0
```

### Property-Based Behaviors

Each declared property is associated with a *behavior*, which you can access
with the $-prefixed property name.

```coffee
alice.$followerCount.onValue (count) ->
  console.log "Alice's follower count changed to #{count}"

alice.$followerCount.becomesGreaterThan(1000).onValue ->
  console.log "Alice just crested 1000 followers!"
```

For more on what's possible with behaviors, see the documentation for
[emissary][emissary].

### Behavior-Based Properties

In addition to behaviors based on properties, you can define read-only
properties based on behaviors with the `Model.behavior` class method.

```coffee
{Model, combine} = require 'theorist'

class Person extends Model
  @properties
    firstName: 'Jane'
    lastName: 'Doe'

  @behavior 'fullName', ->
    combine @$firstName, @$lastName, (firstName, lastName) ->
      "#{firstName} #{lastName}"

jane = new Person
expect(jane.fullName).toBe "Jane Doe"
jane.lastName = "Smith"
expect(jane.fullName).toBe "Jane Smith"
```

In the example above, you can still access the behavior object (rather than its
current value) with `jane.$fullName`.

### Id Assignment

The default constructor automatically assigns each model instance a unique
numeric id. You can also call the constructor with in an explicit `id`
parameter, in which case the next automatically generated id is guaranteed to be
larger.

```coffee
alice = new Person(firstName: "Alice")
betty = new Person(id: 22, firstName: "Betty")
claire = new Person(firstName: "Claire")

expect(alice.id).toBe 1 # might be larger if other models have been created
expect(betty.id).toBe 22
expect(claire.id).toBe 23
```

### Destroying

Models have a standard mechanism for being destroyed, in which they release any
retained resources and alert other parts of the application of their
destruction. If you've declared any behaviors, called `::subscribe` on the
model, or retained resources in other ways, it's important to call `::destroy`
when you're done using it.

```coffee
# The `::destroyed` hook will be called when the model is destroyed
Person::destroyed -> # ...

# The 'destroyed' event will be emitted when the model is destroyed
alice.on 'destroyed', -> # ...

alice.destroy()
```

### Additional Mixins

In addition to the methods discussed here, Theorist models include methods from
a few mixins provided by other libraries:

* `Subscriber` and `Emitter` from [emissary][emissary]
* `PropertyAccessors` from [property-accessors][property-accessors]
* `Delegator` from [delegato][delegato]

## Sequences

[emissary]: https://github.com/atom/emissary
[property-accessors]: https://github.com/atom/property-accessors
[delegato]: https://github.com/atom/delegato
