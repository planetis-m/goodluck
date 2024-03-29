import math, ".."/[gametypes, heaparrays, vmath, slottables, utils, sdlpriv]

const Query = {HasDraw2d, HasTransform2d}
const Tolerance = 0.75'f32

proc update(game: var Game, entity: Entity) =
  template transform: untyped = game.world.transform[entity.idx]
  template draw2d: untyped = game.world.draw2d[entity.idx]

  let position = transform.world.origin
  let rotation = transform.world.rotation
  let scale = transform.world.scale

  let width = int32(draw2d.width.float32 * scale.x)
  let height = int32(draw2d.height.float32 * scale.y)

  var x = position.x.int32
  var y = position.y.int32
  if abs(position.x - x.float32) > Tolerance: x = ceil(position.x).int32
  if abs(position.y - y.float32) > Tolerance: y = ceil(position.y).int32

  var rectangle = (
     x - int32(width / 2),
     y - int32(height / 2),
     width.int32,
     height.int32)
  game.renderer.impl.setDrawColor(draw2d.color[0], draw2d.color[1], draw2d.color[2],
      draw2d.color[3])
  game.renderer.impl.fillRect(rectangle)

proc sysDraw2d*(game: var Game) =
  game.renderer.impl.setDrawColor(game.clearColor[0], game.clearColor[1], game.clearColor[2])
  game.renderer.impl.clear()
  for entity, signature in game.world.signature.pairs:
    if Query <= signature:
      update(game, entity)
