import entities
from typetraits import supportsCopyMem
# No bounds checking, entity indices are guaranteed to be between bounds.

type
  Array*[T] = object
    data: ptr array[maxEntities, T]

proc `=destroy`*[T](x: var Array[T]) =
  if x.data != nil:
    when not supportsCopyMem(T):
      for i in 0..<maxEntities: `=destroy`(x[i])
    dealloc(x.data)
proc `=copy`*[T](dest: var Array[T], src: Array[T]) {.error.}

proc initArray*[T](): Array[T] =
  when not supportsCopyMem(T):
    result.data = cast[typeof(result.data)](alloc0(maxEntities * sizeof(T)))
  else:
    result.data = cast[typeof(result.data)](alloc(maxEntities * sizeof(T)))

template checkInit() =
  when compileOption("boundChecks"):
    assert x.data != nil, "array not inititialized"

template get(x, i) =
  checkInit()
  x.data[i]

proc `[]`*[T](x: Array[T]; i: Natural): lent T =
  get(x, i)
proc `[]`*[T](x: var Array[T]; i: Natural): var T =
  get(x, i)

proc `[]=`*[T](x: var Array[T]; i: Natural; y: sink T) =
  checkInit()
  x.data[i] = y

proc clear*[T](x: Array[T]) =
  when not supportsCopyMem(T):
    if x.data != nil:
      for i in 0..<maxEntities: reset(x[i])

template toOpenArray*(x, first, last: typed): untyped =
  toOpenArray(x.data, first, last)
