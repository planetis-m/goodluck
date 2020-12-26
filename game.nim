import
  std / [random, monotimes],
  project2d / [sdlpriv, heaparrays, gametypes, blueprints, slottables, utils],
  project2d / systems / [collide, draw2d, fade, move, shake, transform2d, handleevents]

proc initGame*(windowWidth, windowHeight: int32): Game =
  let sdlContext = sdlInit(InitVideo or InitEvents)
  let window = newWindow("Breakout", SdlWindowPosCentered,
        SdlWindowPosCentered, windowWidth, windowHeight, SdlWindowShown)

  let renderer = newRenderer(window, -1, RendererAccelerated or RendererPresentVsync)

  let world = World(
     signature: initSlotTableOfCap[set[HasComponent]](maxEntities),

     collide: initArray[Collide](),
     draw2d: initArray[Draw2d](),
     fade: initArray[Fade](),
     hierarchy: initArray[Hierarchy](),
     move: initArray[Move](),
     transform: initArray[Transform2d]())

  result = Game(
     world: world,

     windowWidth: windowWidth,
     windowHeight: windowHeight,
     isRunning: true,

     renderer: renderer,
     window: window,
     sdlContext: sdlContext,

     clearColor: [0'u8, 0, 0, 255])

proc update(game: var Game; delta: float32) =
  # The Game engine that consist of these systems
  # Player input and AI
  # Game logic
  sysShake(game, delta)
  sysFade(game, delta)
  # Garbage collection
  cleanup(game, delta)
  # Animation and movement
  sysMove(game, delta)
  sysTransform2d(game, delta)
  # Post-transform logic
  sysCollide(game, delta)
  # Increment the Game engine tick
  inc(game.tickId)

proc render(game: var Game) =
  sysDraw2d(game)
  game.renderer.impl.present()

proc run(game: var Game) =
  var
    lastTime = getMonoTime().ticks

  while true:
    handleEvents(game)
    if not game.isRunning: break

    let now = getMonoTime().ticks

    game.update((now - lastTime) / 1_000_000_000)
    lastTime = now

proc main =
  randomize()
  var game = initGame(740, 555)

  sceneMain(game)
  game.run()

main()
