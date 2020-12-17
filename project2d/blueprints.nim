import random, math, dsl, vmath, gametypes

proc getBall*(world: var World, parent: Entity, x, y: float32): Entity =
  let angle = Pi + rand(1.0) * Pi
  result = world.addBlueprint:
    with:
      Transform2d(translation: Vec2(x: x, y: y), parent: parent)
      Collide(size: Vec2(x: 20.0, y: 20.0))
      Draw2d(width: 20, height: 20, color: [0'u8, 255, 0, 255])
      Move(direction: Vec2(x: cos(angle), y: sin(angle)), speed: 14.0)

proc sceneMain*(game: var Game) =
  game.camera = game.world.addBlueprint:
    with:
      Transform2d()
      Shake(duration: 0.0, strength: 10.0)
    children:
      entity getBall(float32(game.windowWidth / 2),
            float32(game.windowHeight - 60))
