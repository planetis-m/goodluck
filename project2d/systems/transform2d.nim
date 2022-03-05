import ".." / [gametypes, heaparrays, vmath, mixins, utils, slottables, bitsets]

const Query = sig(HasTransform2d, HasHierarchy, HasDirty)

proc update(world: var World, entity: Entity; delta: float32) =
  template `?=`(name, value): bool = (let name = value; name != invalidId)
  template transform: untyped = world.transform[entity.idx]
  template hierarchy: untyped = world.hierarchy[entity.idx]

  world.rmComponent(entity, HasDirty)
  let local = compose(transform.scale, transform.rotation, transform.translation)
  if parentId ?= hierarchy.parent:
    template parentTransform: untyped = world.transform[parentId.idx]
    transform.world = parentTransform.world * local
  else:
    transform.world = local

proc sysTransform2d*(game: var Game; delta: float32) =
  for entity in queryAll(game.world, game.camera, Query):
    update(game.world, entity, delta)
