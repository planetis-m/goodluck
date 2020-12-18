# Goodluck Nim port

This is a port of [Goodluck](https://github.com/piesku/goodluck) to Nim.
Check my post [Intro to ECS by example](docs/intro.rst) for an introduction to the ECS design pattern.
It also incorporates improvements done by me. These are explained below.

## Entity management was redesigned

The original codebase when updating a system or creating a new entity, it iterates up
to ``MAX_ENTITIES``. This was eliminated by using a specialized data structure.

For entity management (creation, deletion) a ``SlotMap`` is used. It also holds
a dense sequence of ``set[HasComponent]`` which is the "signature" for each entity.
A signature is a bit-set describing the component composition of an entity.
This is used for iterating over all entities, skipping the ones that don't match a system's "registered" components.
These are encoded as `Query`, another bit-set and the check performed is: `signature * Query == Query`.

## Fixed timestep with interpolation

Alpha value is used to interpolate between next and previous transforms. Interpolation function
for `angles` was implemented.

## Custom vector math library

A type safe vector math library was created for use in the game. ``distinct`` types are
used to prohibit operations that have no physical meaning, such as adding two points.

```nim
type
  Rad* = distinct float32

func lerp*(a, b: Rad, t: float32): Rad =
  # interpolates angles

type
  Vec2* = object
    x*, y*: float32

  Point2* {.borrow: `.`.} = distinct Vec2

func `+`*(a, b: Vec2): Vec2
func `-`*(a, b: Point2): Vec2
func `+`*(p: Point2, v: Vec2): Point2
func `-`*(p: Point2, v: Vec2): Point2
func `+`*(a, b: Point2): Point2 {.
    error: "Adding 2 Point2s doesn't make physical sense".}
```

## Acknowledgments

- [Fixed-Time-Step Implementation](http://lspiroengine.com/?p=378)
- [bitquid](http://bitsquid.blogspot.com/2014/10/building-data-oriented-entity-system.html)
- [Goodluck](https://github.com/piesku/goodluck) A hackable template for creating small and fast browser games.
- [rs-breakout](https://github.com/michalbe/rs-breakout)
- [Breakout Tutorial](https://github.com/piesku/breakout/tree/tutorial)
- [Backcountry Architecture](https://piesku.com/backcountry/architecture) lessons learned when using ECS in a game
- [ECS Back and Forth](https://skypjack.github.io/2019-02-14-ecs-baf-part-1/) excellent series that describe ECS designs
- [ECS with sparse array notes](https://gist.github.com/dakom/82551fff5d2b843cbe1601bbaff2acbf)
- #nim-gamedev, a friendly community interested in making games with nim.

## License
This library is distributed under the [MIT license](LICENSE).
