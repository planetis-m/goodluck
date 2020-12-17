An introduction to ECS by example
*********************************

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

In the next paragraphs the design of a simple in-memory database is presented.
I chose an ecommerce store as an example, mainly because everyone has used
an eshop before and ECS resembles relational databases.

Components
==========

Suppose this is a database of an ecommerce store, the main items are customers,
orders and products. These can be modelled with simple objects:

.. code-block:: nim

  type
    Customer* = object
      registered*, verified*: Time
      username*, name*, surname*: array[128, char]
      email*, password*: array[128, char]
      phone*: array[25, char]

    Order* = object
      placed*: Time
      total*: Decimal

    LineItem* = object
      amount*: Positive
      subtotal*: Decimal
      product*: Entity

    Product* = object
      name*: array[128, char]
      description*: array[512, char]
      price*, weight: Decimal
      inStock*: Natural


Why the ``array[N, char]`` arrays, you might ask. Well using types that reference
memory, such as ``string`` is entirely possible. However thats breaks the
promise of data locality, that the strict ECS pattern requires.

Storing Components
------------------

That's why everything is stored in linear arrays. Note that for now these are
sparsely populated and thus space inefficient, their index is explained
:ref:`later<Populating the database>`.

.. code-block:: nim

  type
    Array[T] = object
      data: ptr array[maxEntities, T]

    Database* = object
      customers*: Array[Customer]
      orders*: Array[Order]
      products*: Array[Product]


**Note**: In Nim it's easy to create a custom fixed-size heap array, which is
also automatically memory managed. Writing destructor hooks is explained in this
`document <https://nim-lang.github.io/Nim/destructors.html>`_.

For each component I manually declare a corresponding enum value used to
declare a "has-a" relationship, the usage is explored in a following
:ref:`section<Entity's signature>`.

.. code-block:: nim

  type
    HasComponent* = enum
      HasCustomer,
      HasOrder,
      HasLineItem,
      HasProduct,


Entities
========

A distinct id representing a separate item in the database. It's implemented as:

.. code-block:: nim

  type Entity* = distinct uint16


That posses a restriction on the maximum number of entities that can exist and
will be discussed :ref:`later<Entity management>`.

Simple association
------------------

How would a customer be linked to their placed order? Using their ``Entity`` handle
of course:

.. code-block:: nim

  type
    Order* = object
      ...
      customer*: Entity # one-to-one association


However this requires linear time complexity in order to answer queries such as
"fetch me all the past orders a customer has made", I describe how to achieve
that later.

Entity management
-----------------

The next unanswered question might be, how to verify if an Entity is referring to
live data? To test an entity's validity I rely on a specialized data structure
called a ``SlotMap``. You can insert a value and will be given a unique key which
can be used to retrieve this value.

.. code-block:: nim

  var sm: SlotMap[string]
  let ent: Entity = sm.incl("Banana")

  echo ent # Entity(i: 0, v: 1)


A ``SlotMap`` guarantees that keys to erased values won't work by incrementing a
counter. Meaning that the ``version`` of the internal slot referring to the value
and that of the key's must be equal. When a value is deleted, the slot's version
is incremented, invalidating the key.

This is implemented by storing the version in the higher bits of the number.
Using bit arithmetics to retrieve a key's version:

.. code-block:: nim

  template version(e: Entity): untyped = e.uint16 shr indexBits and versionMask

  var sm: SlotMap[string]
  let ent1 = sm.incl("Pen")

  sm.del(ent1)
  echo ent1 in sm # false
  echo ent1.version # 1 - implementation detail: odd numbers mean occupied


This limits the available bits used for indexing. A wider unsigned type can be
used if more entities are needed. In which case a ``SparseSet``, a data-structure
that keeps the values in a dense internal container, should be used for storing the
components.

Entity's signature
------------------

The ``SlotMap`` is used to store a dense sequence of ``set[HasComponent]`` which is
the signature for each entity. A signature is a bit-set describing the component
composition of an entity.

.. code-block:: nim

  type
    Database* = object
      signatures*: SlotMap[set[HasComponent]]
      ...


Populating the database
-----------------------

The entity returned by the ``SlotMap`` can be used as an index for the "secondary"
component arrays. As you can imagine, these arrays can contain holes as entities
are created and deleted, however the ``SlotMap`` is reusing entities as they become
available.

.. code-block:: nim

  var sm: SlotMap[string]
  let ent1 = sm.incl("Pen")
  let ent2 = sm.incl("Pineapple")
  sm.del(ent1)
  let ent3 = sm.incl("Apple")

  echo ent1 in sm # false
  echo ent1 # Entity(i: 0, v: 1)
  echo ent2 # Entity(i: 1, v: 1)
  echo ent3 # Entity(i: 0, v: 3)


For example, to create a new entity that is a Customer insert ``{HasCustomer}`` in
``signatures``. Then using the entity's index, set the corresponding item in the
``db.customers`` array.

.. code-block:: nim

  template idx*(e: Entity): int = e.int and indexMask

  var db: Database
  let ent = db.signatures.incl({HasCustomer})
  db.customers[ent.idx] = Customer(registered: getTime(), username: "planetis")


Unconstrained Hiearchies
------------------------

There is a one-to-many association between ``Customer`` and ``Order`` and it can be
implemented efficiently with another component, the ``Hierarchy``.

.. code-block:: nim

  type
    Hierarchy* = object
      head*: Entity # the first child, if any.
      prev*, next*: Entity # the prev/next sibling in the list of children for the parent.
      parent*: Entity


This is a standard textbook algorithm for prepending nodes in a linked list. It
is adapted it to work with the ``Entity`` type instead of pointers. For example
inserting a new order is as simple as:

.. code-block:: nim

  template ``?=``(name, value): bool = (let name = value; name != invalidId)
  proc prepend*(h: var Array[Hierarchy], parentId, entity: Entity) =
    hierarchy.prev = invalidId
    hierarchy.next = parent.head
    if headSiblingId ?= parent.head:
      assert headSibling.prev == invalidId
      headSibling.prev = entity
    parent.head = entity


The database may contain multiple hierarchies, e.g.: to represent the many-to-many
associations between ``Order`` and ``Product``.

.. code-block:: nim

  type
    Database* = object
      ...
      # Mappings
      customerOrders*: Array[Hierarchy]
      orderItems*: Array[Hierarchy]


In order to achieve good memory efficiency and iteration speed, sorting the
hiearchies by ``parent`` is needed. A ``SparseSet`` should be used in that case.

Mixins
------

Components can be seen as a mixin idiom, classes that can be "included" rather
"inherited". Prepending an order to the list of orders belonging to a customer:

.. code-block:: nim

  proc mixCustomerOrder*(db: var Database, order, customer: Entity) =
    db.signature[order].incl HasCustomerOrder
    db.customerOrders[order.idx] = Hierarchy(head: invalidId, prev: invalidId,
        next: invalidId, parent: customer)
    if customer != invalidId: prepend(db, customer, order)


Systems
=======

The missing piece of the puzzle, is the code that works on entities having a
certain set of components. These are encoded another bit-set called ``Query`` and
when iterating over all entities, the ones whose signature doesn't contain ``Query``,
are skipped.

.. code-block:: nim

  const Query = {HasOrder, HasCustomerOrder}
  for entity, has in db.signatures.pairs:
    if has * Query == Query:
      let data = db.orders[order.idx]


To fetch the list of orders a customer has made in the past:

.. code-block:: nim

  iterator queryAll*(parent: Entity, query: set[HasComponent]): Entity =
    var frontier = @[parent]
    while frontier.len > 0:
      let entity = frontier.pop()
      if db.signature[entity] * query == query:
        yield entity
      var childId = hierarchy.head
      while childId != invalidId:
        frontier.add(childId)
        childId = childHierarchy.next

  const Query = {HasOrder, HasCustomerOrder}
  for order in queryAll(db.customerOrders, customer, Query):
    let data = db.orders[order.idx]
    # Serialize to JSON


The normal way to send data between systems is to store the data in components.
The total iteration cost for all systems becomes an performance issue if the number of
systems grows or the number of entities is large.

Summary
=======

That is all, I hope you enjoyed the reading it as much as I enjoyed writing it.

- ECS can be applied to many problem domains, but is useful when processing multitudes of data.
- ECS requires hammering a lot of details however is extensible.
- Nim provides plenty of flexibility to write code using most common programming paradigms,
  but is especially well-suited for the ECS pattern.
- Destructors make it trivial to implement data-structures with custom allocators and the semantics you need.
