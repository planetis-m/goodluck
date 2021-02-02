An introduction to ECS by example
*********************************

:author: Antonis Geralis

In this post I'm exploring the inner workings of an strict ECS implementation,
discuss the costs/benefits of each choice with the reader and hopefully answer
the question whether this programming pattern can be easily applied in domains
other than games.

What is an ECS
==============

A pattern used in high-end game engines, simulations, visual FX, CAD/CAM and
other programs. The acronym stands for Entity-Component-System and these are
the building blocks of an ECS. This architecture uses composition, rather
than inheritance. Generally used in top-tier applications where performance
is paramount, while remaining relatively unknown for smaller projects.

The performance advantage over the traditional OOP approach, is achieved by
more efficiently leveraging the CPU instruction and data caches.

In the next sections the design of a simple game is presented.

Components
==========

To model simple movement, the main components are movement and transformations.
``Transform2d`` is used to allow entities to be positioned in the world, while
``Move`` to handle movevement. These can be modelled with plain objects:

.. code-block:: nim

  type
    Move* = object
      direction*: Vec2
      speed*: float32

    Transform2d* = object
      world*: Mat2d      # Matrix relative to the world
      translation*: Vec2 # local translation relative to the parent
      rotation*: Rad
      scale*: Vec2
      children*: array[10, Entity]


Why use an ``array[10, Entity]``, you might ask. Well using types that reference
memory, such as ``seq`` is entirely possible. However that breaks the
promise of data locality, that the strict ECS pattern requires.

Storing components
------------------

That's why everything is stored in linear arrays. Note that for now these are
sparsely populated and thus space inefficient, their index is explained in
`Populating the world`_.

.. code-block:: nim

  type
    Array*[T] = object
      data: ptr array[maxEntities, T]

    World* = object
      moves*: Array[Move]
      cameraShake*: UniquePtr[Shake]
      transforms*: Array[Transform2d]


Notice ``cameraShake`` being a singleton component uses an ``UniquePtr`` instead.

**Note**: In Nim it's easy to create a custom fixed-size heap array, which is
also automatically memory managed. Writing destructor hooks is explained in this
`document <https://nim-lang.github.io/Nim/destructors.html>`_.

For each component I manually declare a corresponding enum value used to
declare a "has-a" relationship, the usage is explored in the section
`Entity's signature`_.

.. code-block:: nim

  type
    HasComponent* = enum
      HasMove,
      HasShake,
      HasTransform2d


Entities
========

A distinct id representing a separate item in the world. It's implemented as:

.. code-block:: nim

  type Entity* = distinct uint16


That posses a restriction on the maximum number of entities that can exist and
will be discussed later_.

Association
-----------

Transforms can have child transforms attached to them. This is used to group
entities into larger wholes (e.g. a character is a hierarchy of body parts).
A scene graph provides a method to transform a child node transform with
respect to its parent node transform.

How would a child be linked to their parent? Using their ``Entity`` handle
of course:

.. code-block:: nim

  type
    Transform2d* = object
      ...
      children*: array[10, Entity]


However this sets a hard limit in the number of children, I describe how to overcome
that in `Unconstrained Hiearchies`_.

Entity management
-----------------

The next unanswered question might be, how to verify if an Entity is referring to
live data? To test an entity's validity I rely on a specialized data structure
called a ``SlotTable``. You can insert a value and will be given a unique key which
can be used to retrieve this value.

.. code-block:: nim

  var st: SlotTable[string]
  let ent: Entity = st.incl("Banana")

  assert st[ent] == "Banana"
  echo ent # Entity(i: 0, v: 1)


A ``SlotTable`` guarantees that keys to erased values won't work by incrementing a
counter. Meaning that the ``version`` of the internal slot referring to the value
and that of the key's, must be equal. When a value is deleted, the slot's version
is incremented, invalidating the key.

.. _later:

This is implemented by storing the version in the higher bits of the number.
Using bitwise operations to retrieve a key's version:

.. code-block:: nim

  template version(e: Entity): untyped = e.uint16 shr indexBits and versionMask

  var st: SlotTable[string]
  let ent1 = st.incl("Pen")

  st.del(ent1)
  echo ent1 in st # false
  echo ent1.version # 1


This limits the available bits used for indexing. A wider unsigned type can be
used if more entities are needed. In which case a ``SparseSet``, a data-structure
that keeps the values in a dense internal container, should be used for storing the
components.

Entity's signature
------------------

The ``SlotTable`` is used to store a dense sequence of ``set[HasComponent]`` which is
the signature for each entity. A signature is a bitset describing the component
composition of an entity. How this is used, is explained in `Systems`_.

.. code-block:: nim

  type
    World* = object
      signatures*: SlotTable[set[HasComponent]]
      ...


Populating the world
--------------------

The entity returned by the ``SlotTable`` can be used as an index for the "secondary"
component arrays. As you can imagine, these arrays can contain holes as entities
are created and deleted, however the ``SlotTable`` is reusing entities as they become
available.

.. code-block:: nim

  var st: SlotTable[string]
  let ent1 = st.incl("Pen")
  let ent2 = st.incl("Pineapple")
  st.del(ent1)
  let ent3 = st.incl("Apple")

  echo ent1 in st # false
  echo ent1 # Entity(i: 0, v: 1)
  echo ent2 # Entity(i: 1, v: 1)
  echo ent3 # Entity(i: 0, v: 3)


For example, to create a new entity that has ``Transform2d``, ``Move`` insert
``{HasTransform2d, HasMove}`` in ``signatures``. Then using the entity's index,
set the corresponding items in the ``world.transforms``, ``world.moves``  arrays.

.. code-block:: nim

  template idx*(e: Entity): int = e.int and indexMask

  var world: World
  let ent = world.signatures.incl({HasTransform2d, HasMove})
  world.transforms[ent.idx] = Transform2D(world: mat2d(), translation: vec2(0, 0),
      rotation: 0.Rad, scale: vec2(1, 1))
  world.moves[ent.idx] = Move(direction: vec2(0, 0), speed: 10'f32)


Unconstrained Hiearchies
------------------------

There is a one-to-many association between parent ``Transform2D`` and its children
and can be implemented efficiently with another component, the ``Hierarchy``. Read
`Systems`_ for how to traverse ``Hierarchy``.

.. code-block:: nim

  type
    Hierarchy* = object
      head*: Entity        # the first child, if any.
      prev*, next*: Entity # the prev/next sibling in the list of children for the parent.
      parent*: Entity      # the parent, if any.


This is a standard textbook algorithm for prepending nodes in a linked list. It
is adapted it to work with the ``Entity`` type instead of pointers.

.. code-block:: nim

  template `?=`(name, value): bool = (let name = value; name != invalidId)
  proc prepend*(h: var Array[Hierarchy], parentId, entity: Entity) =
    hierarchy.prev = invalidId
    hierarchy.next = parent.head
    if headSiblingId ?= parent.head:
      assert headSibling.prev == invalidId
      headSibling.prev = entity
    parent.head = entity


There can be multiple hierarchy arrays, e.g. one for the model and another for
entity scene graphs.

.. code-block:: nim

  type
    World* = object
      ...
      modelSpace*: Array[Hierarchy]
      worldSpace*: Array[Hierarchy]


In order to achieve good memory efficiency and iteration speed, sorting the
hiearchies by ``parent`` is needed. A ``SparseSet`` should be used in that case.

Mixins
------

Components can be seen as a mixin idiom, classes that can be "included" rather
"inherited".

.. code-block:: nim

  proc mixMove*(world: var World, entity: Entity, direction: Vec2, speed: float32) =
    world.signatures[order].incl HasMove
    world.moves[entity.idx] = Move(direction: direction, speed: speed)


Systems
=======

The missing piece of the puzzle, is the code that works on entities having a
certain set of components. These are encoded another bitset called ``Query`` and
when iterating over all entities, the ones whose signature doesn't contain ``Query``,
are skipped.

.. code-block:: nim

  const Query = {HasTransform2d, HasMove}

  proc sysMove*(game: var Game) =
    for entity, signature in game.world.signatures.pairs:
      if signature * Query == Query:
        update(game, entity)


The total iteration cost for all systems becomes a performance issue if the number of
systems grows or the number of entities is large. More complex solutions are can be used
to overcome this problem.

Tags
----

Sometimes values are added to ``HasComponent`` without a companion component. They are
used to efficiently trigger further processing or signal a result.

.. code-block:: nim

  type
    HasComponent = enum
      ...
      HasDirty


Tags are added/removed at run-time without a cost:

.. code-block:: nim

  proc update(game: var Game, entity: Entity) =
    template transform: untyped = game.world.transforms[entity.idx]
    template move: untyped = game.world.moves[entity.idx]

    if move.direction.x != 0.0 or move.direction.y != 0.0:
      transform.translation.x += move.direction.x * move.speed
      transform.translation.y += move.direction.y * move.speed

      world.signatures[entity].incl HasDirty


The normal way to send data between systems is to store the data in components.
Compute the current world position of each entity after it was changed by ``sysMove``:

.. code-block:: nim

  const Query = {HasTransform2d, HasHierarchy, HasDirty}

  iterator queryAll*(parent: Entity, query: set[HasComponent]): Entity =
    var frontier = @[parent]
    while frontier.len > 0:
      let entity = frontier.pop()
      if db.signatures[entity] * query == query:
        yield entity
      var childId = hierarchy.head
      while childId != invalidId:
        frontier.add(childId)
        childId = childHierarchy.next

  proc sysTransform2d*(game: var Game) =
    for entity in queryAll(game.world, game.camera, Query):
      world.signatures[entity].excl HasDirty

      let local = compose(transform.scale, transform.rotation, transform.translation)
      if parentId ?= hierarchy.parent:
        template parentTransform: untyped = world.transforms[parentId.idx]
        transform.world = parentTransform.world * local
      else:
        transform.world = local


``transform.world`` is then accessed by ``sysDraw`` in order to display each
entity to the screen and so on.

Summary
=======

- ECS can be applied to many problem domains, but is useful when processing multitudes of data.
- ECS requires hammering a lot of details however is extensible.
- Nim provides plenty of flexibility to write code using most common programming paradigms,
  but is especially well-suited for the ECS pattern.
- Destructors make it trivial to implement data-structures with custom allocators and the semantics you need.

That is all, I hope you enjoyed the reading it as much as I enjoyed writing it.
