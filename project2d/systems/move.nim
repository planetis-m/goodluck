import ".."/[gametypes, heaparrays, vmath, builddsl, slottables, utils]

const Query = {HasTransform2d, HasMove}

proc update(game: var Game, entity: Entity; delta: float32) =
  template transform: untyped = game.world.transform[entity.idx]
  template move: untyped = game.world.move[entity.idx]

  if move.direction.x != 0.0 or move.direction.y != 0.0:
    transform.translation.x += move.direction.x * move.speed * delta
    transform.translation.y += move.direction.y * move.speed * delta

    game.world.mixDirty(entity)

proc sysMove*(game: var Game; delta: float32) =
  for entity, signature in game.world.signature.pairs:
    if Query <= signature:
      update(game, entity, delta)
