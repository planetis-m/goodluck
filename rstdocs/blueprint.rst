Blueprints DSL
**************

``build`` is a macro that allows you to declaratively specify an entity and its components.
It produces ``mixin`` proc calls that register the components for the entity with the arguments specified.
The macro also supports nested entities (children in the hierarchical scene graph) and composes perfectly
with user-made procedures. These must have signature ``proc (w: World, e: Entity, ...): Entity``.

Examples
========

1. Creates a new entity, with these components, returns the entity handle.

.. code-block:: nim

  let ent1 = game.build(blueprint(with Transform2d(), Fade(step: 0.5),
      Collide(size: vec2(100.0, 20.0)), Move(speed: 600.0)))


2. Specifies a hierarchy of entities, the children (explosion particles) are built inside a loop.
The `build` macro composes with all of Nim's control flow constructs.

.. code-block:: nim

  proc getExplosion*(world: var World, parent: Entity, x, y: float32): Entity =
    let explosions = 32
    let step = (Pi * 2.0) / explosions.float
    let fadeStep = 0.05
    result = world.build:
      blueprint(id = explosion):
        with:
          Transform2d(translation: Vec2(x: x, y: y), parent: parent)
        children:
          for i in 0 ..< explosions:
            blueprint:
              with:
                Transform2d(parent: explosion)
                Draw2d(width: 20, height: 20, color: [255'u8, 255, 255, 255])
                Fade(step: fadeStep)
                Move(direction: Vec2(x: sin(step * i.float), y: cos(step * i.float)), speed: 20.0)


It expands to:

.. code-block:: nim

  let explosion = createEntity(world)
  mixTransform2d(world, explosion, parent = parent)
  for i in 0 ..< explosions:
    let :tmp_1493172298 = createEntity(world)
    mixTransform2d(world, :tmp_1493172298, parent = explosion)
    mixDraw2d(world, :tmp_1493172298, 20, 20, [255'u8, 255, 255, 255])
    mixFade(world, :tmp_1493172298, fadeStep)
    mixMove(world, :tmp_1493172298,
            Vec2(x: sin(step * float(i)), y: cos(step * float(i))), 20.0)
  explosion
