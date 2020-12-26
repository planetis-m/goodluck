import std/[random, math], builddsl, vmath, gametypes

proc createPaddle*(world: var World, parent: Entity, x, y: float32): Entity =
  result = world.build(blueprint):
    with:
      Transform2d(translation: Vec2(x: x, y: y), parent: parent)
      Collide(size: Vec2(x: 100.0, y: 20.0))
      Draw2d(width: 100, height: 20, color: [255'u8, 0, 0, 255])
      Move(speed: 20.0)

proc sceneMain*(game: var Game) =
  game.camera = game.world.build(blueprint):
    with:
      Transform2d()
      Shake(duration: 0.0, strength: 10.0)
    children:
      createPaddle(float32(game.windowWidth / 2), float32(game.windowHeight - 30))
